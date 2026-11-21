//! Runtime nativo freestanding (Linha B) — ADR 0010.
//! Parse/layout GGUF além do stub E27. Forward TinyLlama: ainda não (no_gguf_forward).
#![no_std]

/// Relatório de layout após `prepare`.
#[derive(Clone, Copy, Debug)]
pub struct LayoutReport {
    pub version: u32,
    pub tensor_count: u64,
    pub metadata_kv_count: u64,
    pub tensors_parsed: u64,
    /// Offset do início da região de dados de tensores (após infos + alinhamento).
    pub data_offset: usize,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PrepareError {
    TooShort,
    BadMagic,
    UnsupportedVersion,
    Truncated,
    BadMetadata,
    BadTensorInfo,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ForwardError {
    /// Forward/sampling TinyLlama Q4_K_M ainda não implementado no guest.
    NoForwardImpl,
}

const GGUF_MAGIC: [u8; 4] = *b"GGUF";

/// Prepara layout: valida magic/versão, atravessa metadata e infos de tensores.
pub fn prepare(gguf: &[u8]) -> Result<LayoutReport, PrepareError> {
    if gguf.len() < 24 {
        return Err(PrepareError::TooShort);
    }
    if gguf[0..4] != GGUF_MAGIC {
        return Err(PrepareError::BadMagic);
    }
    let version = read_u32(gguf, 4)?;
    // GGUF v1–v3 usados na prática; TinyLlama canônico = v3.
    if version == 0 || version > 3 {
        return Err(PrepareError::UnsupportedVersion);
    }
    let tensor_count = read_u64(gguf, 8)?;
    let metadata_kv_count = read_u64(gguf, 16)?;
    let mut off = 24usize;

    for _ in 0..metadata_kv_count {
        off = skip_metadata_kv(gguf, off)?;
    }

    let mut tensors_parsed = 0u64;
    for _ in 0..tensor_count {
        off = skip_tensor_info(gguf, off)?;
        tensors_parsed = tensors_parsed.saturating_add(1);
    }

    // Alinhamento GGUF: dados começam no próximo múltiplo de 32.
    let align = 32usize;
    let data_offset = (off + align - 1) & !(align - 1);
    if data_offset > gguf.len() {
        return Err(PrepareError::Truncated);
    }

    Ok(LayoutReport {
        version,
        tensor_count,
        metadata_kv_count,
        tensors_parsed,
        data_offset,
    })
}

/// Tentativa de geração canônica. Etapa 29: sempre `NoForwardImpl` (honesto).
pub fn try_forward_canonical(_layout: &LayoutReport) -> Result<(), ForwardError> {
    Err(ForwardError::NoForwardImpl)
}

fn read_u32(buf: &[u8], off: usize) -> Result<u32, PrepareError> {
    let end = off.checked_add(4).ok_or(PrepareError::Truncated)?;
    let slice = buf.get(off..end).ok_or(PrepareError::Truncated)?;
    let mut a = [0u8; 4];
    a.copy_from_slice(slice);
    Ok(u32::from_le_bytes(a))
}

fn read_u64(buf: &[u8], off: usize) -> Result<u64, PrepareError> {
    let end = off.checked_add(8).ok_or(PrepareError::Truncated)?;
    let slice = buf.get(off..end).ok_or(PrepareError::Truncated)?;
    let mut a = [0u8; 8];
    a.copy_from_slice(slice);
    Ok(u64::from_le_bytes(a))
}

fn skip_string(buf: &[u8], off: usize) -> Result<usize, PrepareError> {
    let len = read_u64(buf, off)? as usize;
    let start = off.checked_add(8).ok_or(PrepareError::Truncated)?;
    let end = start.checked_add(len).ok_or(PrepareError::Truncated)?;
    if end > buf.len() {
        return Err(PrepareError::Truncated);
    }
    Ok(end)
}

fn value_scalar_size(ty: u32) -> Option<usize> {
    match ty {
        0 | 1 | 7 => Some(1),   // u8/i8/bool
        2 | 3 => Some(2),       // u16/i16
        4 | 5 | 6 => Some(4),   // u32/i32/f32
        10 | 11 | 12 => Some(8), // u64/i64/f64
        _ => None,
    }
}

fn skip_value(buf: &[u8], off: usize, ty: u32) -> Result<usize, PrepareError> {
    match ty {
        8 => skip_string(buf, off), // STRING
        9 => {
            // ARRAY: type u32 + count u64 + elements
            let elem_ty = read_u32(buf, off)?;
            let count = read_u64(buf, off + 4)? as usize;
            let mut cur = off
                .checked_add(4 + 8)
                .ok_or(PrepareError::BadMetadata)?;
            if elem_ty == 8 {
                for _ in 0..count {
                    cur = skip_string(buf, cur)?;
                }
                Ok(cur)
            } else {
                let sz = value_scalar_size(elem_ty).ok_or(PrepareError::BadMetadata)?;
                let nbytes = count.checked_mul(sz).ok_or(PrepareError::BadMetadata)?;
                let end = cur.checked_add(nbytes).ok_or(PrepareError::Truncated)?;
                if end > buf.len() {
                    return Err(PrepareError::Truncated);
                }
                Ok(end)
            }
        }
        _ => {
            let sz = value_scalar_size(ty).ok_or(PrepareError::BadMetadata)?;
            let end = off.checked_add(sz).ok_or(PrepareError::Truncated)?;
            if end > buf.len() {
                return Err(PrepareError::Truncated);
            }
            Ok(end)
        }
    }
}

fn skip_metadata_kv(buf: &[u8], off: usize) -> Result<usize, PrepareError> {
    let after_key = skip_string(buf, off)?;
    let ty = read_u32(buf, after_key)?;
    skip_value(buf, after_key + 4, ty)
}

fn skip_tensor_info(buf: &[u8], off: usize) -> Result<usize, PrepareError> {
    // name: string
    let after_name = skip_string(buf, off)?;
    // n_dims: u32
    let n_dims = read_u32(buf, after_name)? as usize;
    let mut cur = after_name
        .checked_add(4)
        .ok_or(PrepareError::BadTensorInfo)?;
    // dims: n_dims × u64
    let dims_bytes = n_dims
        .checked_mul(8)
        .ok_or(PrepareError::BadTensorInfo)?;
    cur = cur
        .checked_add(dims_bytes)
        .ok_or(PrepareError::Truncated)?;
    if cur > buf.len() {
        return Err(PrepareError::Truncated);
    }
    // type: u32
    let _ggml_type = read_u32(buf, cur)?;
    cur = cur.checked_add(4).ok_or(PrepareError::Truncated)?;
    // offset: u64 (relative to data section)
    let _tensor_off = read_u64(buf, cur)?;
    cur = cur.checked_add(8).ok_or(PrepareError::Truncated)?;
    Ok(cur)
}

#[cfg(test)]
mod tests {
    extern crate std;
    use super::*;
    use std::fs;
    use std::path::PathBuf;
    use std::vec::Vec;

    #[test]
    fn prepare_canonical_gguf_layout() {
        let mut root = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        root.pop();
        let path = root.join("models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf");
        if !path.is_file() {
            return; // CI sem pesos: skip silencioso
        }
        let data: Vec<u8> = fs::read(&path).expect("read gguf");
        let layout = prepare(&data).expect("prepare");
        assert_eq!(layout.version, 3);
        assert!(layout.tensor_count > 100);
        assert_eq!(layout.tensors_parsed, layout.tensor_count);
        assert!(layout.data_offset > 24);
        assert!(layout.data_offset < data.len());
        assert!(try_forward_canonical(&layout).is_err());
    }
}
