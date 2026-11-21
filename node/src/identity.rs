//! Identidade ed25519 + PeerId (Rede IA Livre v1).
//! PeerId = hex lowercase da chave pública (32 bytes → 64 chars).

use std::fs;
use std::path::{Path, PathBuf};

use ed25519_dalek::{Signature, Signer, SigningKey, Verifier, VerifyingKey};
use rand::rngs::OsRng;

/// Fingerprint estável: hex lowercase da pubkey ed25519.
pub fn peer_id_from_verifying(vk: &VerifyingKey) -> String {
    hex::encode(vk.as_bytes())
}

pub fn peer_id_from_signing(sk: &SigningKey) -> String {
    peer_id_from_verifying(&sk.verifying_key())
}

/// Carrega 32 bytes de seed ou gera e persiste em `path`.
pub fn load_or_generate_key(path: &Path) -> Result<SigningKey, String> {
    if path.exists() {
        let bytes = fs::read(path).map_err(|e| format!("ler chave {}: {e}", path.display()))?;
        if bytes.len() != 32 {
            return Err(format!(
                "chave {}: esperado 32 bytes, obtido {}",
                path.display(),
                bytes.len()
            ));
        }
        let mut seed = [0u8; 32];
        seed.copy_from_slice(&bytes);
        return Ok(SigningKey::from_bytes(&seed));
    }
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| format!("criar dir de chave {}: {e}", parent.display()))?;
    }
    let sk = SigningKey::generate(&mut OsRng);
    fs::write(path, sk.to_bytes())
        .map_err(|e| format!("gravar chave {}: {e}", path.display()))?;
    // Melhor esforço: permissão restrita em Unix.
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = fs::set_permissions(path, fs::Permissions::from_mode(0o600));
    }
    Ok(sk)
}

pub fn default_key_path(alias: &str) -> PathBuf {
    PathBuf::from(format!("build/node-keys/{alias}.key"))
}

pub fn pubkey_hex(sk: &SigningKey) -> String {
    hex::encode(sk.verifying_key().as_bytes())
}

pub fn sign(sk: &SigningKey, msg: &[u8]) -> String {
    hex::encode(sk.sign(msg).to_bytes())
}

pub fn verify_sig(pubkey_hex: &str, msg: &[u8], sig_hex: &str) -> bool {
    let Ok(pk_bytes) = hex::decode(pubkey_hex) else {
        return false;
    };
    let Ok(sig_bytes) = hex::decode(sig_hex) else {
        return false;
    };
    if pk_bytes.len() != 32 || sig_bytes.len() != 64 {
        return false;
    }
    let mut pk_arr = [0u8; 32];
    pk_arr.copy_from_slice(&pk_bytes);
    let mut sig_arr = [0u8; 64];
    sig_arr.copy_from_slice(&sig_bytes);
    let Ok(vk) = VerifyingKey::from_bytes(&pk_arr) else {
        return false;
    };
    let sig = Signature::from_bytes(&sig_arr);
    vk.verify(msg, &sig).is_ok()
}

/// Confere PeerId == hex(pubkey).
pub fn peer_id_matches_pubkey(peer_id: &str, pubkey_hex: &str) -> bool {
    peer_id.eq_ignore_ascii_case(pubkey_hex) && peer_id.len() == 64 && pubkey_hex.len() == 64
}
