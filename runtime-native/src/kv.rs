//! KV cache GQA multi-posição — Etapa 43 / ADR 0014.
//! Layout por camada: K/V com `n_kv_head × head_dim` por posição.

use crate::attn::{HEAD_DIM, N_KV_DIM, N_KV_HEAD};
use crate::ForwardError;

/// Camadas TinyLlama 1.1B.
pub const N_LAYER: usize = 22;
/// Capacidade de posições (= len do prompt canônico).
pub const MAX_SEQ: usize = 16;
/// Meta preferida (caminho A).
pub const PREFILL_LAYERS_TARGET: usize = 22;
/// Subset guest honesto (caminho B) — ADR 0014: 22L×16 inviável no timeout QEMU debug.
pub const PREFILL_LAYERS_GUEST: usize = 2;
/// Posições no guest (≥2). Prompt completo (16) fica no host test; QEMU debug não cabe.
pub const PREFILL_POS_GUEST: usize = 2;

/// Bytes totais K+V para `n_layers` × `MAX_SEQ` × `N_KV_DIM` × f32 × 2.
pub fn kv_bytes_for_layers(n_layers: usize) -> u32 {
    let per = (n_layers * MAX_SEQ * N_KV_DIM * 4 * 2) as u32;
    per
}

/// Cache K/V estático (UEFI-safe; single-threaded).
pub struct KvCache {
    pub n_layers: usize,
    pub n_pos: usize,
}

// SAFETY: guest single-thread / testes serializados.
static mut KV_K: [[[f32; N_KV_DIM]; MAX_SEQ]; N_LAYER] = [[[0.0; N_KV_DIM]; MAX_SEQ]; N_LAYER];
static mut KV_V: [[[f32; N_KV_DIM]; MAX_SEQ]; N_LAYER] = [[[0.0; N_KV_DIM]; MAX_SEQ]; N_LAYER];

impl KvCache {
    /// Zera contadores; buffers persistem (zerados sob demanda no write).
    pub fn begin(n_layers: usize) -> Result<Self, ForwardError> {
        if n_layers == 0 || n_layers > N_LAYER {
            return Err(ForwardError::BadDims);
        }
        Ok(Self {
            n_layers,
            n_pos: 0,
        })
    }

    pub fn bytes(&self) -> u32 {
        kv_bytes_for_layers(self.n_layers)
    }

    pub fn write_kv(
        &mut self,
        layer: usize,
        pos: usize,
        k: &[f32; N_KV_DIM],
        v: &[f32; N_KV_DIM],
    ) -> Result<(), ForwardError> {
        if layer >= self.n_layers || pos >= MAX_SEQ {
            return Err(ForwardError::BadDims);
        }
        // SAFETY: single-threaded.
        unsafe {
            KV_K[layer][pos] = *k;
            KV_V[layer][pos] = *v;
        }
        if pos + 1 > self.n_pos {
            self.n_pos = pos + 1;
        }
        Ok(())
    }

    pub fn k_at(&self, layer: usize, pos: usize) -> Result<&[f32; N_KV_DIM], ForwardError> {
        if layer >= self.n_layers || pos >= self.n_pos {
            return Err(ForwardError::BadDims);
        }
        Ok(unsafe { &*core::ptr::addr_of!(KV_K[layer][pos]) })
    }

    pub fn v_at(&self, layer: usize, pos: usize) -> Result<&[f32; N_KV_DIM], ForwardError> {
        if layer >= self.n_layers || pos >= self.n_pos {
            return Err(ForwardError::BadDims);
        }
        Ok(unsafe { &*core::ptr::addr_of!(KV_V[layer][pos]) })
    }

    /// Checksum L1 de K+V em (layer, pos) — prova write/read.
    pub fn checksum_pos(&self, layer: usize, pos: usize) -> Result<u32, ForwardError> {
        let k = self.k_at(layer, pos)?;
        let v = self.v_at(layer, pos)?;
        let mut acc = 0f32;
        for i in 0..N_KV_DIM {
            let a = k[i];
            let b = v[i];
            acc += if a >= 0.0 { a } else { -a };
            acc += if b >= 0.0 { b } else { -b };
        }
        Ok((acc * 1000.0) as u32)
    }
}

#[allow(dead_code)]
pub fn _kv_head_dim_assert() {
    let _ = (N_KV_HEAD, HEAD_DIM);
}
