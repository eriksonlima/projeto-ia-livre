//! Tool `read_local` (Etapa 54): leitura só sob roots allowlisted.

use std::fs;
use std::path::{Path, PathBuf};

const MAX_BYTES: u64 = 64 * 1024;
const ALLOWED_ROOTS: &[&str] = &["agent/fixtures", "build/agent-memory"];

fn canonicalize_under_cwd(path: &Path) -> Result<PathBuf, String> {
    let cwd = std::env::current_dir().map_err(|e| format!("cwd: {e}"))?;
    let joined = if path.is_absolute() {
        path.to_path_buf()
    } else {
        cwd.join(path)
    };
    fs::canonicalize(&joined).map_err(|e| format!("read_local: path inválido {}: {e}", path.display()))
}

fn is_allowed(canon: &Path) -> Result<bool, String> {
    let cwd = std::env::current_dir().map_err(|e| format!("cwd: {e}"))?;
    for root in ALLOWED_ROOTS {
        let root_abs = cwd.join(root);
        let root_canon = match fs::canonicalize(&root_abs) {
            Ok(p) => p,
            Err(_) => continue, // root ausente → não permite
        };
        if canon.starts_with(&root_canon) {
            return Ok(true);
        }
    }
    Ok(false)
}

/// Lê arquivo allowlisted; retorna conteúdo UTF-8 truncado a MAX_BYTES.
pub fn read_local(path: &Path) -> Result<String, String> {
    let canon = canonicalize_under_cwd(path)?;
    if !is_allowed(&canon)? {
        return Err(format!(
            "read_local: fora da allowlist: {} (roots: agent/fixtures, build/agent-memory)",
            path.display()
        ));
    }
    let meta = fs::metadata(&canon).map_err(|e| format!("read_local: metadata: {e}"))?;
    if !meta.is_file() {
        return Err("read_local: não é arquivo".into());
    }
    if meta.len() > MAX_BYTES {
        return Err(format!(
            "read_local: arquivo > {MAX_BYTES} bytes ({})",
            meta.len()
        ));
    }
    let bytes = fs::read(&canon).map_err(|e| format!("read_local: ler: {e}"))?;
    String::from_utf8(bytes).map_err(|_| "read_local: conteúdo não é UTF-8".into())
}

pub const PROOF_PATH: &str = "agent/fixtures/read-local-smoke.txt";
pub const PROOF_TEXT: &str = "prova-read-local-ia-livre";
