//! CLI do protótipo do ambiente de autonomia (Etapa 7).
//! Loop: prompt → runtime (subprocesso) → ferramenta `note` → escrita na memória.
//! Marcadores desta fatia: `IA_LIVRE_TOOL_OK` (+ `IA_LIVRE_RUNTIME_USED=1`).
//! Ver docs/ambiente-autonomia-prototipo.md.

use std::env;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode, Stdio};
use std::time::{SystemTime, UNIX_EPOCH};

const USAGE: &str = "\
Uso: ia-livre-agent [--model <path>] [--memory <path>] [--n-predict <n>] [--runtime-bin <path>]

Protótipo da camada 3 (autonomia) no host Linux.
Consome o runtime CPU existente; não exige o SO IA Livre / QEMU / UEFI.
Ver docs/ambiente-autonomia-prototipo.md.
";

const DEFAULT_MODEL: &str = "models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf";
const DEFAULT_MEMORY: &str = "build/agent-memory/memory.jsonl";
const DEFAULT_N_PREDICT: u32 = 16;
/// Prompt de prova alinhado ao runtime (Etapa 5).
const PROOF_PROMPT: &str = "Complete em uma frase: O Projeto IA Livre é";
/// Texto canônico gravado pela ferramenta `note` no cenário de prova.
const PROOF_NOTE: &str = "prova-autonomia-ia-livre";

struct Config {
    model: PathBuf,
    memory: PathBuf,
    n_predict: u32,
    runtime_bin: Option<PathBuf>,
}

fn parse_args() -> Result<Config, i32> {
    let args: Vec<String> = env::args().skip(1).collect();
    let mut model = PathBuf::from(DEFAULT_MODEL);
    let mut memory = PathBuf::from(DEFAULT_MEMORY);
    let mut n_predict = DEFAULT_N_PREDICT;
    let mut runtime_bin: Option<PathBuf> = None;

    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "-h" | "--help" => {
                print!("{USAGE}");
                return Err(0);
            }
            "--model" => {
                i += 1;
                let Some(v) = args.get(i) else {
                    eprintln!("erro: --model exige um caminho");
                    return Err(2);
                };
                model = PathBuf::from(v);
            }
            "--memory" => {
                i += 1;
                let Some(v) = args.get(i) else {
                    eprintln!("erro: --memory exige um caminho");
                    return Err(2);
                };
                memory = PathBuf::from(v);
            }
            "--n-predict" => {
                i += 1;
                let Some(raw) = args.get(i) else {
                    eprintln!("erro: --n-predict exige um inteiro");
                    return Err(2);
                };
                match raw.parse::<u32>() {
                    Ok(n) if n > 0 => n_predict = n,
                    _ => {
                        eprintln!("erro: --n-predict inválido: {raw}");
                        return Err(2);
                    }
                }
            }
            "--runtime-bin" => {
                i += 1;
                let Some(v) = args.get(i) else {
                    eprintln!("erro: --runtime-bin exige um caminho");
                    return Err(2);
                };
                runtime_bin = Some(PathBuf::from(v));
            }
            other => {
                eprintln!("erro: argumento desconhecido: {other}");
                eprint!("{USAGE}");
                return Err(2);
            }
        }
        i += 1;
    }

    Ok(Config {
        model,
        memory,
        n_predict,
        runtime_bin,
    })
}

fn unix_ts() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

/// Escapa string para JSON mínimo (aspas + barras).
fn json_escape(s: &str) -> String {
    let mut out = String::with_capacity(s.len() + 8);
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if c.is_control() => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out
}

fn ensure_parent_dir(path: &Path) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent)
                .map_err(|e| format!("criar dir {}: {e}", parent.display()))?;
        }
    }
    Ok(())
}

/// Ferramenta `note`: appenda uma linha JSONL ao store de memória.
fn tool_note(memory: &Path, text: &str) -> Result<(), String> {
    ensure_parent_dir(memory)?;
    let line = format!(
        "{{\"ts\":{},\"kind\":\"note\",\"text\":\"{}\"}}\n",
        unix_ts(),
        json_escape(text)
    );
    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(memory)
        .map_err(|e| format!("abrir memória {}: {e}", memory.display()))?;
    file.write_all(line.as_bytes())
        .map_err(|e| format!("escrever memória: {e}"))?;
    Ok(())
}

fn find_runtime_bin(explicit: Option<&Path>) -> Result<PathBuf, String> {
    if let Some(p) = explicit {
        if p.is_file() {
            return Ok(p.to_path_buf());
        }
        return Err(format!("--runtime-bin não encontrado: {}", p.display()));
    }

    // Preferir binário já buildado no target do workspace (Makefile fixa CARGO_TARGET_DIR).
    let candidates = [
        PathBuf::from("target/debug/ia-livre-runtime"),
        PathBuf::from("target/release/ia-livre-runtime"),
    ];
    for c in &candidates {
        if c.is_file() {
            return Ok(c.clone());
        }
    }

    // Fallback: CARGO_TARGET_DIR herdado (sandbox/cache)
    if let Ok(dir) = env::var("CARGO_TARGET_DIR") {
        for profile in ["debug", "release"] {
            let p = PathBuf::from(&dir).join(profile).join("ia-livre-runtime");
            if p.is_file() {
                return Ok(p);
            }
        }
    }

    Err(
        "binário ia-livre-runtime não encontrado; rode: cargo build -p ia-livre-runtime"
            .into(),
    )
}

fn invoke_runtime(config: &Config) -> Result<String, String> {
    let bin = find_runtime_bin(config.runtime_bin.as_deref())?;
    if !config.model.is_file() {
        return Err(format!(
            "modelo não encontrado: {}\nRode: ./scripts/fetch-model.sh",
            config.model.display()
        ));
    }

    let output = Command::new(&bin)
        .arg("--model")
        .arg(&config.model)
        .arg("--prompt")
        .arg(PROOF_PROMPT)
        .arg("--n-predict")
        .arg(config.n_predict.to_string())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .output()
        .map_err(|e| format!("falha ao executar {}: {e}", bin.display()))?;

    let stdout = String::from_utf8_lossy(&output.stdout).into_owned();
    let stderr = String::from_utf8_lossy(&output.stderr).into_owned();
    let combined = format!("{stdout}{stderr}");

    if !output.status.success() {
        let tail: String = combined
            .chars()
            .rev()
            .take(2000)
            .collect::<String>()
            .chars()
            .rev()
            .collect();
        return Err(format!(
            "runtime exit {:?}\n---- stderr/stdout ----\n{tail}",
            output.status.code()
        ));
    }

    if !combined.contains("IA_LIVRE_INFER_OK") {
        return Err(format!(
            "runtime não emitiu IA_LIVRE_INFER_OK\n---- saída ----\n{combined}"
        ));
    }

    Ok(stdout)
}

fn run(config: &Config) -> Result<(), String> {
    // 1) Carregar memória (existência; conteúdo pleno na Task 3)
    if config.memory.is_file() {
        let _ = fs::read_to_string(&config.memory);
    }

    // 2–3) Prompt fixo + runtime
    let generated = invoke_runtime(config)?;
    println!("IA_LIVRE_RUNTIME_USED=1");
    // Ecoa trecho útil (sem poluir demais)
    for line in generated.lines().take(8) {
        println!("runtime: {line}");
    }

    // 4–5) Cenário de prova: ferramenta garantida (não depende do SLM)
    tool_note(&config.memory, PROOF_NOTE)?;
    println!("IA_LIVRE_TOOL_OK");
    println!("IA_LIVRE_TOOL=note");
    println!("IA_LIVRE_MEMORY_PATH={}", config.memory.display());

    Ok(())
}

fn main() -> ExitCode {
    let config = match parse_args() {
        Ok(c) => c,
        Err(0) => return ExitCode::SUCCESS,
        Err(_) => return ExitCode::from(2),
    };

    match run(&config) {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("erro: {e}");
            ExitCode::from(1)
        }
    }
}
