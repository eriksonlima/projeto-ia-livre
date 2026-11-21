//! FFN SwiGLU `blk.N` + Prefill multi-token — Etapa 33/43.
//! Buffers grandes em `static` para caber no stack UEFI.

use crate::attn::{attn_layer0_on, attn_layer_on, load_f32_vec, rms_norm, AttnLayerReport};
use crate::kv::{KvCache, PREFILL_LAYERS_GUEST, PREFILL_LAYERS_TARGET, PREFILL_POS_GUEST};
use crate::names::blk_name;
use crate::{
    dequant_block_q4_k, embed_token, find_tensor, f16_to_f32, ForwardError, LayoutReport,
    TensorInfo, N_EMBD, QK_K, BLOCK_Q4_K_SIZE, CANONICAL_PROMPT_TOKEN_IDS,
};

const GGML_TYPE_Q4_K: u32 = 12;
const GGML_TYPE_Q6_K: u32 = 14;
const BLOCK_Q6_K_SIZE: usize = 210;

pub const N_FF: usize = 5632;

#[derive(Clone, Copy, Debug)]
pub struct FfnLayerReport {
    pub ffn_checksum_milli: u32,
}

#[derive(Clone, Copy, Debug)]
pub struct PrefillReport {
    pub n_layers: u32,
    pub attn: AttnLayerReport,
    pub ffn: FfnLayerReport,
    pub prefill_checksum_milli: u32,
}

#[derive(Clone, Copy, Debug)]
pub struct PrefillMultiReport {
    pub n_layers: u32,
    pub n_pos: u32,
    pub kv_bytes: u32,
    pub kv_checksum_milli: u32,
    pub prefill_checksum_milli: u32,
    /// true se n_layers == 22 (caminho A).
    pub full_22l: bool,
}

// Workspace FFN (UEFI-safe).
static mut WS_GATE: [f32; N_FF] = [0.0; N_FF];
static mut WS_UP: [f32; N_FF] = [0.0; N_FF];

fn silu(x: f32) -> f32 {
    let s = 1.0 / (1.0 + libm_exp(-x));
    x * s
}

fn libm_exp(x: f32) -> f32 {
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

fn matvec_q4k_to_ff(
    gguf: &[u8],
    layout: &LayoutReport,
    tensor: &TensorInfo,
    x: &[f32; N_EMBD],
    out: &mut [f32; N_FF],
) -> Result<(), ForwardError> {
    if tensor.ggml_type != GGML_TYPE_Q4_K {
        return Err(ForwardError::UnsupportedType);
    }
    if tensor.dims[0] != N_EMBD as u64 || tensor.dims[1] != N_FF as u64 {
        return Err(ForwardError::BadDims);
    }
    let blocks_per_row = N_EMBD / QK_K;
    let row_bytes = blocks_per_row * BLOCK_Q4_K_SIZE;
    let base = layout.data_offset + tensor.data_rel as usize;
    let mut wrow = [0f32; N_EMBD];
    for o in 0..N_FF {
        let abs = base + o * row_bytes;
        for b in 0..blocks_per_row {
            let boff = abs + b * BLOCK_Q4_K_SIZE;
            if boff + BLOCK_Q4_K_SIZE > gguf.len() {
                return Err(ForwardError::Truncated);
            }
            let mut block = [0f32; QK_K];
            dequant_block_q4_k(&gguf[boff..boff + BLOCK_Q4_K_SIZE], &mut block)?;
            let dst = b * QK_K;
            wrow[dst..dst + QK_K].copy_from_slice(&block);
        }
        let mut acc = 0f32;
        for i in 0..N_EMBD {
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

fn matvec_q6k_ffn_down(
    gguf: &[u8],
    layout: &LayoutReport,
    tensor: &TensorInfo,
    x: &[f32; N_FF],
    out: &mut [f32; N_EMBD],
) -> Result<(), ForwardError> {
    if tensor.ggml_type != GGML_TYPE_Q6_K {
        return Err(ForwardError::UnsupportedType);
    }
    if tensor.dims[0] != N_FF as u64 || tensor.dims[1] != N_EMBD as u64 {
        return Err(ForwardError::BadDims);
    }
    let blocks_per_row = N_FF / QK_K;
    let row_bytes = blocks_per_row * BLOCK_Q6_K_SIZE;
    let base = layout.data_offset + tensor.data_rel as usize;
    for o in 0..N_EMBD {
        let abs = base + o * row_bytes;
        let mut acc = 0f32;
        for b in 0..blocks_per_row {
            let boff = abs + b * BLOCK_Q6_K_SIZE;
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
        out[o] = acc;
    }
    Ok(())
}

/// FFN SwiGLU completa da camada `layer`.
pub fn try_ffn_layer(
    gguf: &[u8],
    layout: &LayoutReport,
    layer: usize,
    x: &[f32; N_EMBD],
    out: &mut [f32; N_EMBD],
) -> Result<FfnLayerReport, ForwardError> {
    let mut name_buf = [0u8; 64];
    let mut wn = [0f32; N_EMBD];
    {
        let n = blk_name(&mut name_buf, layer, b"ffn_norm.weight")?;
        load_f32_vec(gguf, layout, n, &mut wn)?;
    }
    let mut xn = [0f32; N_EMBD];
    rms_norm(x, &wn, &mut xn);

    let tg = {
        let n = blk_name(&mut name_buf, layer, b"ffn_gate.weight")?;
        find_tensor(gguf, layout, n)?
    };
    let tu = {
        let n = blk_name(&mut name_buf, layer, b"ffn_up.weight")?;
        find_tensor(gguf, layout, n)?
    };
    let td = {
        let n = blk_name(&mut name_buf, layer, b"ffn_down.weight")?;
        find_tensor(gguf, layout, n)?
    };

    // SAFETY: single-threaded guest / tests serializados.
    let (gate, up) = unsafe {
        (
            &mut *core::ptr::addr_of_mut!(WS_GATE),
            &mut *core::ptr::addr_of_mut!(WS_UP),
        )
    };
    matvec_q4k_to_ff(gguf, layout, &tg, &xn, gate)?;
    matvec_q4k_to_ff(gguf, layout, &tu, &xn, up)?;
    for i in 0..N_FF {
        gate[i] = silu(gate[i]) * up[i];
    }

    let mut down = [0f32; N_EMBD];
    matvec_q6k_ffn_down(gguf, layout, &td, gate, &mut down)?;

    let mut acc = 0f32;
    for i in 0..N_EMBD {
        out[i] = x[i] + down[i];
        let v = out[i];
        acc += if v >= 0.0 { v } else { -v };
    }
    Ok(FfnLayerReport {
        ffn_checksum_milli: (acc * 1000.0) as u32,
    })
}

/// Compat E33: FFN camada 0.
pub fn try_ffn_layer0(
    gguf: &[u8],
    layout: &LayoutReport,
    x: &[f32; N_EMBD],
    out: &mut [f32; N_EMBD],
) -> Result<FfnLayerReport, ForwardError> {
    try_ffn_layer(gguf, layout, 0, x, out)
}

/// Prefill mínimo honesto: 1 token × camada 0 (attn → FFN). Compat E33.
pub fn try_prefill_layer0(
    gguf: &[u8],
    layout: &LayoutReport,
) -> Result<PrefillReport, ForwardError> {
    let last = *CANONICAL_PROMPT_TOKEN_IDS
        .last()
        .ok_or(ForwardError::BadToken)?;
    let mut x = [0f32; N_EMBD];
    let _ = embed_token(gguf, layout, last, &mut x)?;
    let mut after_attn = [0f32; N_EMBD];
    let attn = attn_layer0_on(gguf, layout, &x, &mut after_attn)?;
    let mut after_ffn = [0f32; N_EMBD];
    let ffn = try_ffn_layer0(gguf, layout, &after_attn, &mut after_ffn)?;
    let mut acc = 0f32;
    for &v in after_ffn.iter() {
        acc += if v >= 0.0 { v } else { -v };
    }
    Ok(PrefillReport {
        n_layers: 1,
        attn,
        ffn,
        prefill_checksum_milli: (acc * 1000.0) as u32,
    })
}

/// Prefill multi-token × `n_layers` × `n_pos` com KV GQA.
pub fn try_prefill_multi(
    gguf: &[u8],
    layout: &LayoutReport,
    n_layers: usize,
    n_pos: usize,
) -> Result<PrefillMultiReport, ForwardError> {
    if n_layers == 0 || n_layers > PREFILL_LAYERS_TARGET {
        return Err(ForwardError::BadDims);
    }
    let max_pos = CANONICAL_PROMPT_TOKEN_IDS.len();
    if n_pos < 2 || n_pos > max_pos {
        return Err(ForwardError::BadToken);
    }
    let mut kv = KvCache::begin(n_layers)?;
    let mut x = [0f32; N_EMBD];
    let mut after_attn = [0f32; N_EMBD];
    let mut after_ffn = [0f32; N_EMBD];
    let mut last_cs = 0u32;

    for (pos, &tid) in CANONICAL_PROMPT_TOKEN_IDS.iter().take(n_pos).enumerate() {
        let _ = embed_token(gguf, layout, tid, &mut x)?;
        for layer in 0..n_layers {
            let _ = attn_layer_on(gguf, layout, layer, pos, &x, &mut after_attn, &mut kv)?;
            let ffn = try_ffn_layer(gguf, layout, layer, &after_attn, &mut after_ffn)?;
            x = after_ffn;
            last_cs = ffn.ffn_checksum_milli;
        }
    }

    // Prova KV: checksum em layer0 pos0 e pos1 (multi-pos).
    let cs0 = kv.checksum_pos(0, 0)?;
    let cs1 = kv.checksum_pos(0, 1)?;
    if cs0 == 0 || cs1 == 0 {
        return Err(ForwardError::DequantFail);
    }
    if n_layers >= 2 {
        let cs_l1 = kv.checksum_pos(1, 0)?;
        if cs_l1 == 0 {
            return Err(ForwardError::DequantFail);
        }
    }

    Ok(PrefillMultiReport {
        n_layers: n_layers as u32,
        n_pos: n_pos as u32,
        kv_bytes: kv.bytes(),
        kv_checksum_milli: cs0.wrapping_add(cs1),
        prefill_checksum_milli: last_cs,
        full_22l: n_layers == PREFILL_LAYERS_TARGET && n_pos == max_pos,
    })
}

/// Prefill guest canônico (subset ADR 0014: 2L × 2 pos).
pub fn try_prefill_canonical_guest(
    gguf: &[u8],
    layout: &LayoutReport,
) -> Result<PrefillMultiReport, ForwardError> {
    try_prefill_multi(gguf, layout, PREFILL_LAYERS_GUEST, PREFILL_POS_GUEST)
}
