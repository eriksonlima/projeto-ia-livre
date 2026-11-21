//! FFN SwiGLU (blk.0) + Prefill mínimo — Etapa 33 Task 2.
//! Buffers grandes em `static` para caber no stack UEFI.

use crate::attn::{attn_layer0_on, load_f32_vec, rms_norm, AttnLayerReport};
use crate::{
    dequant_block_q4_k, embed_token, find_tensor, f16_to_f32, ForwardError, LayoutReport,
    TensorInfo, N_EMBD, QK_K, BLOCK_Q4_K_SIZE, CANONICAL_PROMPT_TOKEN_IDS,
};

const GGML_TYPE_Q4_K: u32 = 12;
const GGML_TYPE_Q6_K: u32 = 14;
const BLOCK_Q6_K_SIZE: usize = 210;

pub const N_FF: usize = 5632;

const FFN_NORM: &[u8] = b"blk.0.ffn_norm.weight";
const FFN_GATE: &[u8] = b"blk.0.ffn_gate.weight";
const FFN_UP: &[u8] = b"blk.0.ffn_up.weight";
const FFN_DOWN: &[u8] = b"blk.0.ffn_down.weight";

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

/// FFN SwiGLU completa da camada 0.
pub fn try_ffn_layer0(
    gguf: &[u8],
    layout: &LayoutReport,
    x: &[f32; N_EMBD],
    out: &mut [f32; N_EMBD],
) -> Result<FfnLayerReport, ForwardError> {
    let mut wn = [0f32; N_EMBD];
    load_f32_vec(gguf, layout, FFN_NORM, &mut wn)?;
    let mut xn = [0f32; N_EMBD];
    rms_norm(x, &wn, &mut xn);

    let tg = find_tensor(gguf, layout, FFN_GATE)?;
    let tu = find_tensor(gguf, layout, FFN_UP)?;
    let td = find_tensor(gguf, layout, FFN_DOWN)?;

    // SAFETY: single-threaded guest / tests serializados.
    let (gate, up) = unsafe { (&mut *core::ptr::addr_of_mut!(WS_GATE), &mut *core::ptr::addr_of_mut!(WS_UP)) };
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

/// Prefill mínimo honesto: 1 token × camada 0 (attn → FFN).
/// 22 camadas / KV multi-token → `NoFullPrefill` (Task 2/3).
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
