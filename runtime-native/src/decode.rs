//! Decode autoregressivo + sampling greedy — Etapa 44 / ADR 0015.
//! Usa as N layers do Prefill/KV guest (subset E43). Logits via `output.weight` Q6_K.

use crate::attn::{attn_layer_on, load_f32_vec, rms_norm, HEAD_DIM};
use crate::ffn::try_ffn_layer;
use crate::kv::{KvCache, PREFILL_LAYERS_GUEST, PREFILL_POS_GUEST};
use crate::{
    embed_token, find_tensor, f16_to_f32, ForwardError, LayoutReport, N_EMBD, QK_K,
    CANONICAL_PROMPT_TOKEN_IDS,
};

const GGML_TYPE_F32: u32 = 0;
const GGML_TYPE_Q6_K: u32 = 14;
const BLOCK_Q6_K_SIZE: usize = 210;
const VOCAB: usize = 32000;
/// Preferido canônico; guest pode usar menos se documentado.
pub const N_PREDICT_TARGET: usize = 32;
/// Guest inicial: 1 token (prova Decode+métrica sem estourar QEMU).
pub const N_PREDICT_GUEST: usize = 1;

#[derive(Clone, Copy, Debug)]
pub struct DecodeReport {
    pub n_layers: u32,
    pub n_prefill_pos: u32,
    pub n_predict: u32,
    pub last_token_id: u32,
    pub decode_checksum_milli: u32,
}

fn matvec_q6k_row_dot(
    gguf: &[u8],
    layout: &LayoutReport,
    data_rel: u64,
    row: usize,
    x: &[f32; N_EMBD],
) -> Result<f32, ForwardError> {
    let blocks_per_row = N_EMBD / QK_K;
    let row_bytes = blocks_per_row * BLOCK_Q6_K_SIZE;
    let base = layout
        .data_offset
        .checked_add(data_rel as usize)
        .ok_or(ForwardError::Truncated)?
        .checked_add(row.checked_mul(row_bytes).ok_or(ForwardError::Truncated)?)
        .ok_or(ForwardError::Truncated)?;
    let mut acc = 0f32;
    for b in 0..blocks_per_row {
        let boff = base + b * BLOCK_Q6_K_SIZE;
        if boff + BLOCK_Q6_K_SIZE > gguf.len() {
            return Err(ForwardError::Truncated);
        }
        let mut block = [0f32; QK_K];
        dequant_block_q6_k(&gguf[boff..boff + BLOCK_Q6_K_SIZE], &mut block)?;
        let x_off = b * QK_K;
        for i in 0..QK_K {
            acc += block[i] * x[x_off + i];
        }
    }
    Ok(acc)
}

fn dequant_block_q6_k(block: &[u8], out: &mut [f32; QK_K]) -> Result<(), ForwardError> {
    if block.len() < BLOCK_Q6_K_SIZE {
        return Err(ForwardError::DequantFail);
    }
    let ql = &block[0..128];
    let qh = &block[128..192];
    let scales = &block[192..208];
    let d = f16_to_f32(u16::from_le_bytes([block[208], block[209]]));
    let mut y = 0usize;
    let mut ql_off = 0usize;
    let mut qh_off = 0usize;
    let mut sc_off = 0usize;
    for _ in 0..2 {
        for l in 0..32 {
            let is = l / 16;
            let q1 = ((ql[ql_off + l] & 0xF) as i32 | (((qh[qh_off + l] as i32) >> 0) & 3) << 4) - 32;
            let q2 = ((ql[ql_off + l + 32] & 0xF) as i32 | (((qh[qh_off + l] as i32) >> 2) & 3) << 4) - 32;
            let q3 = ((ql[ql_off + l] >> 4) as i32 | (((qh[qh_off + l] as i32) >> 4) & 3) << 4) - 32;
            let q4 = ((ql[ql_off + l + 32] >> 4) as i32 | (((qh[qh_off + l] as i32) >> 6) & 3) << 4) - 32;
            let s0 = scales[sc_off + is] as i8 as f32;
            let s2 = scales[sc_off + is + 2] as i8 as f32;
            let s4 = scales[sc_off + is + 4] as i8 as f32;
            let s6 = scales[sc_off + is + 6] as i8 as f32;
            out[y + l] = d * s0 * (q1 as f32);
            out[y + l + 32] = d * s2 * (q2 as f32);
            out[y + l + 64] = d * s4 * (q3 as f32);
            out[y + l + 96] = d * s6 * (q4 as f32);
        }
        y += 128;
        ql_off += 64;
        qh_off += 32;
        sc_off += 8;
    }
    Ok(())
}

/// Argmax greedy sobre vocab completo (streaming — sem buffer de 32k logits).
pub fn sample_argmax(
    gguf: &[u8],
    layout: &LayoutReport,
    hidden: &[f32; N_EMBD],
) -> Result<u32, ForwardError> {
    let mut wn = [0f32; N_EMBD];
    load_f32_vec(gguf, layout, b"output_norm.weight", &mut wn)?;
    let mut xn = [0f32; N_EMBD];
    rms_norm(hidden, &wn, &mut xn);

    let tout = find_tensor(gguf, layout, b"output.weight")?;
    if tout.ggml_type != GGML_TYPE_Q6_K {
        return Err(ForwardError::UnsupportedType);
    }
    if tout.dims[0] != N_EMBD as u64 || tout.dims[1] != VOCAB as u64 {
        return Err(ForwardError::BadDims);
    }

    let mut best_id = 0u32;
    let mut best = -1.0e30f32;
    for row in 0..VOCAB {
        let score = matvec_q6k_row_dot(gguf, layout, tout.data_rel, row, &xn)?;
        if score > best {
            best = score;
            best_id = row as u32;
        }
    }
    let _ = (HEAD_DIM, GGML_TYPE_F32);
    Ok(best_id)
}

/// Prefill guest + Decode `n_predict` tokens (greedy). Atualiza KV.
pub fn try_decode_generate(
    gguf: &[u8],
    layout: &LayoutReport,
    n_layers: usize,
    n_prefill_pos: usize,
    n_predict: usize,
) -> Result<DecodeReport, ForwardError> {
    if n_predict == 0 || n_layers == 0 {
        return Err(ForwardError::BadDims);
    }
    // Prefill interno (reconstroi KV + hidden).
    let mut kv = KvCache::begin(n_layers)?;
    let mut x = [0f32; N_EMBD];
    let mut after_attn = [0f32; N_EMBD];
    let mut after_ffn = [0f32; N_EMBD];

    for (pos, &tid) in CANONICAL_PROMPT_TOKEN_IDS
        .iter()
        .take(n_prefill_pos)
        .enumerate()
    {
        let _ = embed_token(gguf, layout, tid, &mut x)?;
        for layer in 0..n_layers {
            let _ = attn_layer_on(gguf, layout, layer, pos, &x, &mut after_attn, &mut kv)?;
            let _ = try_ffn_layer(gguf, layout, layer, &after_attn, &mut after_ffn)?;
            x = after_ffn;
        }
    }

    let mut last_id = 0u32;
    let mut cs = 0u32;
    for step in 0..n_predict {
        let tok = sample_argmax(gguf, layout, &x)?;
        last_id = tok;
        cs = cs.wrapping_add(tok);
        let pos = n_prefill_pos + step;
        if pos >= crate::kv::MAX_SEQ {
            // Cap de KV: para após preencher MAX_SEQ (Decode mínimo honesto).
            return Ok(DecodeReport {
                n_layers: n_layers as u32,
                n_prefill_pos: n_prefill_pos as u32,
                n_predict: (step + 1) as u32,
                last_token_id: last_id,
                decode_checksum_milli: cs,
            });
        }
        let _ = embed_token(gguf, layout, tok, &mut x)?;
        for layer in 0..n_layers {
            let _ = attn_layer_on(gguf, layout, layer, pos, &x, &mut after_attn, &mut kv)?;
            let _ = try_ffn_layer(gguf, layout, layer, &after_attn, &mut after_ffn)?;
            x = after_ffn;
        }
    }

    Ok(DecodeReport {
        n_layers: n_layers as u32,
        n_prefill_pos: n_prefill_pos as u32,
        n_predict: n_predict as u32,
        last_token_id: last_id,
        decode_checksum_milli: cs,
    })
}

/// Caminho guest: Prefill E43 + Decode `N_PREDICT_GUEST` (um único passe).
pub fn try_decode_canonical_guest(
    gguf: &[u8],
    layout: &LayoutReport,
) -> Result<DecodeReport, ForwardError> {
    try_decode_generate(
        gguf,
        layout,
        PREFILL_LAYERS_GUEST,
        PREFILL_POS_GUEST,
        N_PREDICT_GUEST,
    )
}
