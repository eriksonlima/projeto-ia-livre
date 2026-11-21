//! Descoberta além de LAN (Etapa 39): lista bootstrap / arquivo.
//! Bootstrap ≠ identidade — IDENT ed25519 permanece a âncora.

use std::fs;
use std::path::Path;

/// Carrega endpoints `host:port` de flags repetíveis e arquivo.
pub fn load_bootstrap(cli: &[String], file: Option<&Path>) -> Result<Vec<String>, String> {
    let mut out = Vec::new();
    for raw in cli {
        for part in raw.split(',') {
            let t = part.trim();
            if !t.is_empty() {
                out.push(t.to_string());
            }
        }
    }
    if let Some(path) = file {
        let text = fs::read_to_string(path)
            .map_err(|e| format!("--bootstrap-file {}: {e}", path.display()))?;
        for line in text.lines() {
            let t = line.trim();
            if t.is_empty() || t.starts_with('#') {
                continue;
            }
            out.push(t.to_string());
        }
    }
    Ok(out)
}
