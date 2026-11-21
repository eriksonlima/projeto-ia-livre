//! Runtime nativo freestanding (Linha B) — ADR 0010 / 0012 / 0013.
//! Layout + mapa + dequant Q4_K + op + tokenize/embed (E32).
//! Geração canônica TinyLlama: Prefill/Decode/sampling ainda não.
#![no_std]

/// Dimensão de embedding TinyLlama 1.1B.
pub const N_EMBD: usize = 2048;

/// Prompt canônico (mesmo texto da Linha A / harness).
pub const CANONICAL_PROMPT: &str = "Complete em uma frase: O Projeto IA Livre é";

/// Token IDs do prompt canônico (TinyLlama SPM + BOS), capturados via
/// `ia-livre-runtime` / llama.cpp (`IA_LIVRE_DUMP_TOKEN_IDS=1`). Não é um
/// tokenizer SPM completo no guest — ids fixos para a carga canônica.
pub const CANONICAL_PROMPT_TOKEN_IDS: &[u32] = &[
    1, 25034, 953, 3672, 5227, 344, 29901, 438, 1019, 4026, 29877, 306, 29909,
    16238, 276, 904,
];

const TOKEN_EMBD_NAME: &[u8] = b"token_embd.weight";
/// Blocos Q4_K por linha de embedding (2048 / 256).
const BLOCKS_PER_EMBD_ROW: usize = N_EMBD / QK_K;

/// Relatório de layout após `prepare`.
#[derive(Clone, Copy, Debug)]
pub struct LayoutReport {
    pub version: u32,
    pub tensor_count: u64,
    pub metadata_kv_count: u64,
    pub tensors_parsed: u64,
    pub data_offset: usize,
    /// Offset no arquivo onde começa a tabela de infos de tensores.
    pub tensor_info_offset: usize,
}

#[derive(Clone, Copy, Debug)]
pub struct TensorInfo {
    /// Offset do nome (string GGUF) no arquivo — para comparação byte a byte.
    pub name_off: usize,
    pub name_len: usize,
    pub n_dims: u32,
    pub dims: [u64; 4],
    pub ggml_type: u32,
    /// Offset relativo à seção de dados.
    pub data_rel: u64,
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
    /// Geração Prefill+Decode+sampling ainda não implementada.
    NoGenerate,
    /// Tokenize+embed+camada ok; decode/sampling ainda não (E32 fallback).
    NoDecode,
    TensorNotFound,
    UnsupportedType,
    Truncated,
    DequantFail,
    BadToken,
    BadDims,
}

const GGUF_MAGIC: [u8; 4] = *b"GGUF";
const GGML_TYPE_Q4_K: u32 = 12;
const QK_K: usize = 256;
const BLOCK_Q4_K_SIZE: usize = 144; // half+half+12+128

/// Prepara layout e localiza o início das infos de tensores.
pub fn prepare(gguf: &[u8]) -> Result<LayoutReport, PrepareError> {
    if gguf.len() < 24 {
        return Err(PrepareError::TooShort);
    }
    if gguf[0..4] != GGUF_MAGIC {
        return Err(PrepareError::BadMagic);
    }
    let version = read_u32(gguf, 4)?;
    if version == 0 || version > 3 {
        return Err(PrepareError::UnsupportedVersion);
    }
    let tensor_count = read_u64(gguf, 8)?;
    let metadata_kv_count = read_u64(gguf, 16)?;
    let mut off = 24usize;

    for _ in 0..metadata_kv_count {
        off = skip_metadata_kv(gguf, off)?;
    }
    let tensor_info_offset = off;

    let mut tensors_parsed = 0u64;
    for _ in 0..tensor_count {
        off = skip_tensor_info(gguf, off)?;
        tensors_parsed = tensors_parsed.saturating_add(1);
    }

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
        tensor_info_offset,
    })
}

/// Busca tensor por nome UTF-8 exato.
pub fn find_tensor(gguf: &[u8], layout: &LayoutReport, name: &[u8]) -> Result<TensorInfo, ForwardError> {
    let mut off = layout.tensor_info_offset;
    for _ in 0..layout.tensor_count {
        let name_off = off.checked_add(8).ok_or(ForwardError::Truncated)?;
        let name_len = read_u64(gguf, off).map_err(|_| ForwardError::Truncated)? as usize;
        let name_end = name_off
            .checked_add(name_len)
            .ok_or(ForwardError::Truncated)?;
        if name_end > gguf.len() {
            return Err(ForwardError::Truncated);
        }
        let matches = &gguf[name_off..name_end] == name;
        let after_name = name_end;
        let n_dims = read_u32(gguf, after_name).map_err(|_| ForwardError::Truncated)?;
        let mut cur = after_name
            .checked_add(4)
            .ok_or(ForwardError::Truncated)?;
        let mut dims = [0u64; 4];
        for d in 0..(n_dims as usize).min(4) {
            dims[d] = read_u64(gguf, cur).map_err(|_| ForwardError::Truncated)?;
            cur = cur.checked_add(8).ok_or(ForwardError::Truncated)?;
        }
        if (n_dims as usize) > 4 {
            cur = cur
                .checked_add(((n_dims as usize) - 4) * 8)
                .ok_or(ForwardError::Truncated)?;
        }
        let ggml_type = read_u32(gguf, cur).map_err(|_| ForwardError::Truncated)?;
        cur = cur.checked_add(4).ok_or(ForwardError::Truncated)?;
        let data_rel = read_u64(gguf, cur).map_err(|_| ForwardError::Truncated)?;
        cur = cur.checked_add(8).ok_or(ForwardError::Truncated)?;
        if matches {
            return Ok(TensorInfo {
                name_off,
                name_len,
                n_dims,
                dims,
                ggml_type,
                data_rel,
            });
        }
        off = cur;
    }
    Err(ForwardError::TensorNotFound)
}

/// Dequantiza o primeiro bloco Q4_K (256 pesos) de um tensor; retorna checksum Σ|x|.
pub fn dequant_q4k_first_block(
    gguf: &[u8],
    layout: &LayoutReport,
    tensor: &TensorInfo,
    out: &mut [f32; QK_K],
) -> Result<u32, ForwardError> {
    if tensor.ggml_type != GGML_TYPE_Q4_K {
        return Err(ForwardError::UnsupportedType);
    }
    let abs = layout
        .data_offset
        .checked_add(tensor.data_rel as usize)
        .ok_or(ForwardError::Truncated)?;
    let end = abs
        .checked_add(BLOCK_Q4_K_SIZE)
        .ok_or(ForwardError::Truncated)?;
    if end > gguf.len() {
        return Err(ForwardError::Truncated);
    }
    dequant_block_q4_k(&gguf[abs..end], out)?;
    let mut acc = 0f32;
    for &v in out.iter() {
        acc += if v >= 0.0 { v } else { -v };
    }
    // checksum estável em u32 (milli-units)
    Ok((acc * 1000.0) as u32)
}

/// Op parcial honesta: dot do vetor dequantizado consigo (norma²) — prova de uso dos pesos.
pub fn forward_op_dot_self(weights: &[f32; QK_K]) -> u32 {
    let mut acc = 0f32;
    for &v in weights.iter() {
        acc += v * v;
    }
    (acc * 1000.0) as u32
}

/// Pipeline Etapa 31: mapa + dequant + op; geração canônica ainda falha.
pub fn try_forward_partial(gguf: &[u8], layout: &LayoutReport) -> Result<PartialReport, ForwardError> {
    // Tensor Q4_K relativamente pequeno: blk.0.attn_k.weight
    let name = b"blk.0.attn_k.weight";
    let tensor = find_tensor(gguf, layout, name)?;
    let mut buf = [0f32; QK_K];
    let dequant_cs = dequant_q4k_first_block(gguf, layout, &tensor, &mut buf)?;
    let op_cs = forward_op_dot_self(&buf);
    Ok(PartialReport {
        tensor_ggml_type: tensor.ggml_type,
        dequant_checksum_milli: dequant_cs,
        op_checksum_milli: op_cs,
    })
}

/// Tokenização mínima do prompt canônico (ids fixos; sem SPM no guest).
pub fn tokenize_canonical() -> TokenizeReport {
    TokenizeReport {
        n_tokens: CANONICAL_PROMPT_TOKEN_IDS.len() as u32,
        first_id: CANONICAL_PROMPT_TOKEN_IDS[0],
        last_id: *CANONICAL_PROMPT_TOKEN_IDS
            .last()
            .unwrap_or(&0),
    }
}

/// Lookup de uma linha de `token_embd.weight` (Q4_K, dims [2048, vocab]).
pub fn embed_token(
    gguf: &[u8],
    layout: &LayoutReport,
    token_id: u32,
    out: &mut [f32; N_EMBD],
) -> Result<u32, ForwardError> {
    let tensor = find_tensor(gguf, layout, TOKEN_EMBD_NAME)?;
    if tensor.ggml_type != GGML_TYPE_Q4_K {
        return Err(ForwardError::UnsupportedType);
    }
    if tensor.n_dims < 2 || tensor.dims[0] != N_EMBD as u64 {
        return Err(ForwardError::BadDims);
    }
    let vocab = tensor.dims[1];
    if token_id as u64 >= vocab {
        return Err(ForwardError::BadToken);
    }
    let row_bytes = BLOCKS_PER_EMBD_ROW
        .checked_mul(BLOCK_Q4_K_SIZE)
        .ok_or(ForwardError::Truncated)?;
    let abs = layout
        .data_offset
        .checked_add(tensor.data_rel as usize)
        .ok_or(ForwardError::Truncated)?
        .checked_add((token_id as usize).checked_mul(row_bytes).ok_or(ForwardError::Truncated)?)
        .ok_or(ForwardError::Truncated)?;
    let end = abs
        .checked_add(row_bytes)
        .ok_or(ForwardError::Truncated)?;
    if end > gguf.len() {
        return Err(ForwardError::Truncated);
    }
    let mut acc = 0f32;
    for b in 0..BLOCKS_PER_EMBD_ROW {
        let boff = abs + b * BLOCK_Q4_K_SIZE;
        let mut block_out = [0f32; QK_K];
        dequant_block_q4_k(&gguf[boff..boff + BLOCK_Q4_K_SIZE], &mut block_out)?;
        let dst = b * QK_K;
        out[dst..dst + QK_K].copy_from_slice(&block_out);
        for &v in block_out.iter() {
            acc += if v >= 0.0 { v } else { -v };
        }
    }
    Ok((acc * 1000.0) as u32)
}

/// Tokenize + embed do último token do prompt canônico (evidência E32 Task 2).
pub fn try_embed_canonical(
    gguf: &[u8],
    layout: &LayoutReport,
) -> Result<EmbedReport, ForwardError> {
    let tok = tokenize_canonical();
    let last = *CANONICAL_PROMPT_TOKEN_IDS
        .last()
        .ok_or(ForwardError::BadToken)?;
    let mut emb = [0f32; N_EMBD];
    let checksum = embed_token(gguf, layout, last, &mut emb)?;
    if checksum == 0 {
        return Err(ForwardError::DequantFail);
    }
    Ok(EmbedReport {
        n_tokens: tok.n_tokens,
        token_id: last,
        embed_checksum_milli: checksum,
    })
}

/// Tentativa de geração canônica — ainda sem Prefill/Decode/sampling.
pub fn try_forward_canonical(
    gguf: &[u8],
    layout: &LayoutReport,
) -> Result<(), ForwardError> {
    let _ = try_forward_partial(gguf, layout)?;
    let _ = try_embed_canonical(gguf, layout)?;
    // Camada / decode virão na Task 3; até lá sem tokens.
    Err(ForwardError::NoGenerate)
}

#[derive(Clone, Copy, Debug)]
pub struct PartialReport {
    pub tensor_ggml_type: u32,
    pub dequant_checksum_milli: u32,
    pub op_checksum_milli: u32,
}

#[derive(Clone, Copy, Debug)]
pub struct TokenizeReport {
    pub n_tokens: u32,
    pub first_id: u32,
    pub last_id: u32,
}

#[derive(Clone, Copy, Debug)]
pub struct EmbedReport {
    pub n_tokens: u32,
    pub token_id: u32,
    pub embed_checksum_milli: u32,
}

fn dequant_block_q4_k(block: &[u8], out: &mut [f32; QK_K]) -> Result<(), ForwardError> {
    if block.len() < BLOCK_Q4_K_SIZE {
        return Err(ForwardError::DequantFail);
    }
    let d = f16_to_f32(u16::from_le_bytes([block[0], block[1]]));
    let dmin = f16_to_f32(u16::from_le_bytes([block[2], block[3]]));
    let scales = &block[4..16];
    let qs = &block[16..144];

    // Layout llama.cpp block_q4_K: 8 sub-blocos de 32; scales packed.
    for j in 0..QK_K / 64 {
        let is = j * 64;
        let sc0 = (scales[j] & 0xF) as i32;
        let sc1 = (scales[j] >> 4) as i32;
        let m0 = (scales[j + 8] & 0xF) as i32; // may be wrong packing — use common K-quants layout
        let m1 = (scales[j + 8] >> 4) as i32;
        // Correct packing for q4_K (from ggml): scales[0..4] and scales[4..8] interleaved differently.
        // Use the standard algorithm from llama.cpp dequantize_row_q4_K:
        let _ = (m0, m1);
        let _ = (sc0, sc1);
        let _ = is;
    }

    // Implementação alinhada a ggml dequantize_row_q4_K (sub-blocos 32):
    let mut y = 0usize;
    for j in 0..QK_K / 64 {
        let q = &qs[j * 32..j * 32 + 32];
        let (sc_lo, sc_hi, m_lo, m_hi) = unpack_q4k_scales(scales, j);
        let d1 = d * (sc_lo as f32);
        let m1 = dmin * (m_lo as f32);
        let d2 = d * (sc_hi as f32);
        let m2 = dmin * (m_hi as f32);
        for l in 0..32 {
            let v = q[l] as i32;
            out[y + l] = d1 * ((v & 0xF) as f32) - m1;
            out[y + l + 32] = d2 * ((v >> 4) as f32) - m2;
        }
        y += 64;
    }
    Ok(())
}

/// Unpacks scale/min nibbles for subblock pair `j` (0..3) — ggml q4_K layout.
fn unpack_q4k_scales(scales: &[u8], j: usize) -> (u8, u8, u8, u8) {
    // From ggml-quants.c get_scale_min_k4:
    // scales are 6-bit packed in 12 bytes for 8 scale+min pairs.
    // Simplified: use 4-bit nibbles from first 8 bytes as approximation for smoke test
    // — replaced with get_scale_min_k4-compatible extraction:
    let mut sc = [0u8; 8];
    let mut m = [0u8; 8];
    for i in 0..4 {
        sc[i] = scales[i] & 63;
        m[i] = scales[i + 4] & 63;
    }
    for i in 0..2 {
        sc[i + 4] = (scales[i + 8] & 15) | ((scales[i] & 192) >> 2);
        m[i + 4] = (scales[i + 8] >> 4) | ((scales[i + 2] & 192) >> 2);
        sc[i + 6] = (scales[i + 10] & 15) | ((scales[i + 1] & 192) >> 2);
        m[i + 6] = (scales[i + 10] >> 4) | ((scales[i + 3] & 192) >> 2);
    }
    let a = j * 2;
    (sc[a], sc[a + 1], m[a], m[a + 1])
}

fn f16_to_f32(h: u16) -> f32 {
    // IEEE half → f32
    let sign = ((h >> 15) & 1) as u32;
    let exp = ((h >> 10) & 0x1f) as u32;
    let mant = (h & 0x3ff) as u32;
    let f = if exp == 0 {
        if mant == 0 {
            sign << 31
        } else {
            // subnormal
            let mut m = mant;
            let mut e = 127 - 15 + 1;
            while m & 0x400 == 0 {
                m <<= 1;
                e -= 1;
            }
            m &= 0x3ff;
            (sign << 31) | (e << 23) | (m << 13)
        }
    } else if exp == 31 {
        (sign << 31) | 0x7f800000 | (mant << 13)
    } else {
        (sign << 31) | ((exp + 127 - 15) << 23) | (mant << 13)
    };
    f32::from_bits(f)
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
        0 | 1 | 7 => Some(1),
        2 | 3 => Some(2),
        4 | 5 | 6 => Some(4),
        10 | 11 | 12 => Some(8),
        _ => None,
    }
}

fn skip_value(buf: &[u8], off: usize, ty: u32) -> Result<usize, PrepareError> {
    match ty {
        8 => skip_string(buf, off),
        9 => {
            let elem_ty = read_u32(buf, off)?;
            let count = read_u64(buf, off + 4)? as usize;
            let mut cur = off.checked_add(4 + 8).ok_or(PrepareError::BadMetadata)?;
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
    let after_name = skip_string(buf, off)?;
    let n_dims = read_u32(buf, after_name)? as usize;
    let mut cur = after_name
        .checked_add(4)
        .ok_or(PrepareError::BadTensorInfo)?;
    let dims_bytes = n_dims
        .checked_mul(8)
        .ok_or(PrepareError::BadTensorInfo)?;
    cur = cur
        .checked_add(dims_bytes)
        .ok_or(PrepareError::Truncated)?;
    if cur > buf.len() {
        return Err(PrepareError::Truncated);
    }
    let _ = read_u32(buf, cur)?;
    cur = cur.checked_add(4).ok_or(PrepareError::Truncated)?;
    let _ = read_u64(buf, cur)?;
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

    fn load_canonical_gguf() -> Option<(Vec<u8>, LayoutReport)> {
        let mut root = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        root.pop();
        let path = root.join("models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf");
        if !path.is_file() {
            return None;
        }
        let data: Vec<u8> = fs::read(&path).expect("read gguf");
        let layout = prepare(&data).expect("prepare");
        Some((data, layout))
    }

    #[test]
    fn map_dequant_op_canonical_gguf() {
        let Some((data, layout)) = load_canonical_gguf() else {
            return;
        };
        let t = find_tensor(&data, &layout, b"blk.0.attn_k.weight").expect("find");
        assert_eq!(t.ggml_type, GGML_TYPE_Q4_K);
        let mut buf = [0f32; QK_K];
        let cs = dequant_q4k_first_block(&data, &layout, &t, &mut buf).expect("dequant");
        assert!(cs > 0, "dequant checksum should be non-zero");
        let op = forward_op_dot_self(&buf);
        assert!(op > 0);
        let partial = try_forward_partial(&data, &layout).expect("partial");
        assert_eq!(partial.tensor_ggml_type, GGML_TYPE_Q4_K);
        assert!(matches!(
            try_forward_canonical(&data, &layout),
            Err(ForwardError::NoGenerate)
        ));
    }

    #[test]
    fn tokenize_and_embed_canonical() {
        let tok = tokenize_canonical();
        assert_eq!(tok.n_tokens, 16);
        assert_eq!(tok.first_id, 1);
        assert_eq!(tok.last_id, 904);
        assert_eq!(CANONICAL_PROMPT_TOKEN_IDS.len(), 16);

        let Some((data, layout)) = load_canonical_gguf() else {
            return;
        };
        let emb = find_tensor(&data, &layout, b"token_embd.weight").expect("token_embd");
        assert_eq!(emb.ggml_type, GGML_TYPE_Q4_K);
        assert_eq!(emb.dims[0], N_EMBD as u64);
        assert_eq!(emb.dims[1], 32000);

        let report = try_embed_canonical(&data, &layout).expect("embed");
        assert_eq!(report.n_tokens, 16);
        assert_eq!(report.token_id, 904);
        assert!(report.embed_checksum_milli > 0);

        let mut out = [0f32; N_EMBD];
        let cs = embed_token(&data, &layout, 1, &mut out).expect("bos embed");
        assert!(cs > 0);
        // Linhas distintas devem diferir no checksum (smoke).
        let cs2 = embed_token(&data, &layout, 904, &mut out).expect("last embed");
        assert_ne!(cs, cs2);
    }
}
