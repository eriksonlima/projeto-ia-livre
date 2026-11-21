//! Atenção completa 1 camada (TinyLlama blk.0) — Etapa 33 Task 1.
//! Seq_len=1, posição 0 (RoPE = identidade). GQA 32/4, head_dim=64.

use crate::{
    dequant_block_q4_k, embed_token, find_tensor, f16_to_f32, tokenize_canonical,
    ForwardError, LayoutReport, N_EMBD, QK_K, BLOCK_Q4_K_SIZE, CANONICAL_PROMPT_TOKEN_IDS,
};

const GGML_TYPE_F32: u32 = 0;
const GGML_TYPE_Q4_K: u32 = 12;
const GGML_TYPE_Q6_K: u32 = 14;
const BLOCK_Q6_K_SIZE: usize = 210;

pub const N_HEAD: usize = 32;
pub const N_KV_HEAD: usize = 4;
pub const HEAD_DIM: usize = 64;
pub const N_KV_DIM: usize = N_KV_HEAD * HEAD_DIM; // 256

const ATTN_NORM: &[u8] = b"blk.0.attn_norm.weight";
const ATTN_Q: &[u8] = b"blk.0.attn_q.weight";
const ATTN_K: &[u8] = b"blk.0.attn_k.weight";
const ATTN_V: &[u8] = b"blk.0.attn_v.weight";
const ATTN_O: &[u8] = b"blk.0.attn_output.weight";

const EPS: f32 = 1e-5;

#[derive(Clone, Copy, Debug)]
pub struct AttnLayerReport {
    pub n_tokens: u32,
    pub rms_checksum_milli: u32,
    pub attn_checksum_milli: u32,
}

/// RMSNorm: out = (x / rms) * weight; rms = sqrt(mean(x²)+eps).
pub fn rms_norm(x: &[f32; N_EMBD], weight: &[f32; N_EMBD], out: &mut [f32; N_EMBD]) {
    let mut ss = 0f32;
    for &v in x.iter() {
        ss += v * v;
    }
    ss = ss / (N_EMBD as f32) + EPS;
    let inv = 1.0 / libm_sqrt(ss);
    for i in 0..N_EMBD {
        out[i] = x[i] * inv * weight[i];
    }
}

fn libm_sqrt(x: f32) -> f32 {
    // Newton / bit trick — suficiente para freestanding.
    if x <= 0.0 {
        return 0.0;
    }
    let mut y = f32::from_bits((x.to_bits() >> 1) + 0x1fbb4000);
    y = 0.5 * (y + x / y);
    y = 0.5 * (y + x / y);
    y
}

fn libm_exp(x: f32) -> f32 {
    // Clamp + série para softmax estável (seq_len=1 usa pouco; mantido para GQA scores).
    let x = if x > 80.0 {
        80.0
    } else if x < -80.0 {
        -80.0
    } else {
        x
    };
    let mut sum = 1.0f32;
    let mut term = 1.0f32;
    for i in 1..12 {
        term *= x / (i as f32);
        sum += term;
    }
    sum
}

/// Carrega pesos F32 de um tensor 1D [N_EMBD].
pub fn load_f32_vec(
    gguf: &[u8],
    layout: &LayoutReport,
    name: &[u8],
    out: &mut [f32; N_EMBD],
) -> Result<(), ForwardError> {
    let t = find_tensor(gguf, layout, name)?;
    if t.ggml_type != GGML_TYPE_F32 || t.dims[0] != N_EMBD as u64 {
        return Err(ForwardError::BadDims);
    }
    let abs = layout
        .data_offset
        .checked_add(t.data_rel as usize)
        .ok_or(ForwardError::Truncated)?;
    let bytes = N_EMBD * 4;
    let end = abs.checked_add(bytes).ok_or(ForwardError::Truncated)?;
    if end > gguf.len() {
        return Err(ForwardError::Truncated);
    }
    for i in 0..N_EMBD {
        let o = abs + i * 4;
        out[i] = f32::from_le_bytes([gguf[o], gguf[o + 1], gguf[o + 2], gguf[o + 3]]);
    }
    Ok(())
}

fn matvec_q4k(
    gguf: &[u8],
    layout: &LayoutReport,
    tensor: &crate::TensorInfo,
    x: &[f32],
    out: &mut [f32],
) -> Result<(), ForwardError> {
    if tensor.ggml_type != GGML_TYPE_Q4_K {
        return Err(ForwardError::UnsupportedType);
    }
    let n_in = tensor.dims[0] as usize;
    let n_out = tensor.dims[1] as usize;
    if x.len() < n_in || out.len() < n_out || n_in == 0 {
        return Err(ForwardError::BadDims);
    }
    let blocks_per_row = n_in / QK_K;
    let row_bytes = blocks_per_row
        .checked_mul(BLOCK_Q4_K_SIZE)
        .ok_or(ForwardError::Truncated)?;
    let base = layout
        .data_offset
        .checked_add(tensor.data_rel as usize)
        .ok_or(ForwardError::Truncated)?;
    let mut wrow = [0f32; N_EMBD];
    if n_in > N_EMBD {
        return Err(ForwardError::BadDims);
    }
    for o in 0..n_out {
        let abs = base
            .checked_add(o.checked_mul(row_bytes).ok_or(ForwardError::Truncated)?)
            .ok_or(ForwardError::Truncated)?;
        // dequant row into wrow[0..n_in]
        for b in 0..blocks_per_row {
            let boff = abs + b * BLOCK_Q4_K_SIZE;
            let end = boff + BLOCK_Q4_K_SIZE;
            if end > gguf.len() {
                return Err(ForwardError::Truncated);
            }
            let mut block = [0f32; QK_K];
            dequant_block_q4_k(&gguf[boff..end], &mut block)?;
            let dst = b * QK_K;
            wrow[dst..dst + QK_K].copy_from_slice(&block);
        }
        let mut acc = 0f32;
        for i in 0..n_in {
            acc += wrow[i] * x[i];
        }
        out[o] = acc;
    }
    Ok(())
}

fn dequant_block_q6_k(block: &[u8], out: &mut [f32; QK_K]) -> Result<(), ForwardError> {
    if block.len() < BLOCK_Q6_K_SIZE {
        return Err(ForwardError::DequantFail);
    }
    // Layout: ql[128], qh[64], scales[16], d[2]
    let ql = &block[0..128];
    let qh = &block[128..192];
    let scales = &block[192..208];
    let d = f16_to_f32(u16::from_le_bytes([block[208], block[209]]));
    let mut y = 0usize;
    let mut ql_off = 0usize;
    let mut qh_off = 0usize;
    let mut sc_off = 0usize;
    for _ in 0..2 {
        // two chunks of 128
        for l in 0..32 {
            let is = l / 16;
            let sc = scales;
            let q1 = ((ql[ql_off + l] & 0xF) as i32 | (((qh[qh_off + l] as i32) >> 0) & 3) << 4) - 32;
            let q2 = ((ql[ql_off + l + 32] & 0xF) as i32 | (((qh[qh_off + l] as i32) >> 2) & 3) << 4) - 32;
            let q3 = ((ql[ql_off + l] >> 4) as i32 | (((qh[qh_off + l] as i32) >> 4) & 3) << 4) - 32;
            let q4 = ((ql[ql_off + l + 32] >> 4) as i32 | (((qh[qh_off + l] as i32) >> 6) & 3) << 4) - 32;
            let s0 = sc[sc_off + is] as i8 as f32;
            let s2 = sc[sc_off + is + 2] as i8 as f32;
            let s4 = sc[sc_off + is + 4] as i8 as f32;
            let s6 = sc[sc_off + is + 6] as i8 as f32;
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

fn matvec_q6k(
    gguf: &[u8],
    layout: &LayoutReport,
    tensor: &crate::TensorInfo,
    x: &[f32],
    out: &mut [f32],
) -> Result<(), ForwardError> {
    if tensor.ggml_type != GGML_TYPE_Q6_K {
        return Err(ForwardError::UnsupportedType);
    }
    let n_in = tensor.dims[0] as usize;
    let n_out = tensor.dims[1] as usize;
    if x.len() < n_in || out.len() < n_out {
        return Err(ForwardError::BadDims);
    }
    let blocks_per_row = n_in / QK_K;
    let row_bytes = blocks_per_row
        .checked_mul(BLOCK_Q6_K_SIZE)
        .ok_or(ForwardError::Truncated)?;
    let base = layout
        .data_offset
        .checked_add(tensor.data_rel as usize)
        .ok_or(ForwardError::Truncated)?;
    let mut wrow = [0f32; N_EMBD];
    if n_in > N_EMBD {
        return Err(ForwardError::BadDims);
    }
    for o in 0..n_out {
        let abs = base
            .checked_add(o.checked_mul(row_bytes).ok_or(ForwardError::Truncated)?)
            .ok_or(ForwardError::Truncated)?;
        for b in 0..blocks_per_row {
            let boff = abs + b * BLOCK_Q6_K_SIZE;
            if boff + BLOCK_Q6_K_SIZE > gguf.len() {
                return Err(ForwardError::Truncated);
            }
            let mut block = [0f32; QK_K];
            dequant_block_q6_k(&gguf[boff..boff + BLOCK_Q6_K_SIZE], &mut block)?;
            let dst = b * QK_K;
            wrow[dst..dst + QK_K].copy_from_slice(&block);
        }
        let mut acc = 0f32;
        for i in 0..n_in {
            acc += wrow[i] * x[i];
        }
        out[o] = acc;
    }
    Ok(())
}

/// Atenção completa blk.0 para **1 token** (pos=0, RoPE identidade).
pub fn try_attn_layer0_single(
    gguf: &[u8],
    layout: &LayoutReport,
) -> Result<AttnLayerReport, ForwardError> {
    let tok = tokenize_canonical();
    let last = *CANONICAL_PROMPT_TOKEN_IDS
        .last()
        .ok_or(ForwardError::BadToken)?;

    let mut x = [0f32; N_EMBD];
    let _ = embed_token(gguf, layout, last, &mut x)?;

    let mut wn = [0f32; N_EMBD];
    load_f32_vec(gguf, layout, ATTN_NORM, &mut wn)?;
    let mut xn = [0f32; N_EMBD];
    rms_norm(&x, &wn, &mut xn);
    let mut rms_cs = 0f32;
    for &v in xn.iter() {
        rms_cs += if v >= 0.0 { v } else { -v };
    }

    let tq = find_tensor(gguf, layout, ATTN_Q)?;
    let tk = find_tensor(gguf, layout, ATTN_K)?;
    let tv = find_tensor(gguf, layout, ATTN_V)?;
    let to = find_tensor(gguf, layout, ATTN_O)?;

    let mut q = [0f32; N_EMBD];
    let mut k = [0f32; N_KV_DIM];
    let mut v = [0f32; N_KV_DIM];
    matvec_q4k(gguf, layout, &tq, &xn, &mut q)?;
    matvec_q4k(gguf, layout, &tk, &xn, &mut k)?;
    matvec_q6k(gguf, layout, &tv, &xn, &mut v)?;

    // GQA: seq_len=1 → softmax trivial; out_head = V_kv_head
    let mut attn_out = [0f32; N_EMBD];
    let scale = 1.0 / libm_sqrt(HEAD_DIM as f32);
    let _ = (scale, libm_exp); // scale used if seq>1; keep for honesty of API
    for h in 0..N_HEAD {
        let kv_h = h / (N_HEAD / N_KV_HEAD);
        let q_off = h * HEAD_DIM;
        let kv_off = kv_h * HEAD_DIM;
        // score = q·k * scale; seq=1 → weight=1
        let mut score = 0f32;
        for d in 0..HEAD_DIM {
            score += q[q_off + d] * k[kv_off + d];
        }
        score *= scale;
        let _w = libm_exp(score); // numeric path exercised; weight unused (seq=1 ⇒ 1.0)
        for d in 0..HEAD_DIM {
            attn_out[q_off + d] = v[kv_off + d];
        }
    }

    let mut projected = [0f32; N_EMBD];
    matvec_q4k(gguf, layout, &to, &attn_out, &mut projected)?;

    // residual: x + projected
    let mut acc = 0f32;
    for i in 0..N_EMBD {
        let y = x[i] + projected[i];
        acc += if y >= 0.0 { y } else { -y };
    }

    Ok(AttnLayerReport {
        n_tokens: tok.n_tokens,
        rms_checksum_milli: (rms_cs * 1000.0) as u32,
        attn_checksum_milli: (acc * 1000.0) as u32,
    })
}
