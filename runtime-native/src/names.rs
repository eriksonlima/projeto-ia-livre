//! Nomes GGUF `blk.N.*` (TinyLlama) — Etapa 43.

use crate::ForwardError;

/// Monta `blk.{layer}.{suffix}` em `buf`; retorna fatia válida.
pub fn blk_name<'a>(
    buf: &'a mut [u8; 64],
    layer: usize,
    suffix: &[u8],
) -> Result<&'a [u8], ForwardError> {
    if layer > 99 {
        return Err(ForwardError::BadDims);
    }
    let mut i = 0usize;
    buf[i] = b'b';
    i += 1;
    buf[i] = b'l';
    i += 1;
    buf[i] = b'k';
    i += 1;
    buf[i] = b'.';
    i += 1;
    if layer >= 10 {
        buf[i] = b'0' + (layer / 10) as u8;
        i += 1;
        buf[i] = b'0' + (layer % 10) as u8;
        i += 1;
    } else {
        buf[i] = b'0' + layer as u8;
        i += 1;
    }
    buf[i] = b'.';
    i += 1;
    if i.checked_add(suffix.len()).ok_or(ForwardError::BadDims)? > buf.len() {
        return Err(ForwardError::BadDims);
    }
    buf[i..i + suffix.len()].copy_from_slice(suffix);
    i += suffix.len();
    Ok(&buf[..i])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn blk_name_formats() {
        let mut buf = [0u8; 64];
        assert_eq!(
            blk_name(&mut buf, 0, b"attn_q.weight").unwrap(),
            b"blk.0.attn_q.weight"
        );
        assert_eq!(
            blk_name(&mut buf, 21, b"ffn_down.weight").unwrap(),
            b"blk.21.ffn_down.weight"
        );
    }
}
