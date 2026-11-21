//! CLI do ambiente de autonomia v1 (Etapa 24) — evolui o protótipo Etapa 7.
//! Loop: memória (N=8) → prompt → runtime (subprocesso) → ferramentas allowlist → re-leitura.
//! Marcadores E7: `IA_LIVRE_TOOL_OK`, `IA_LIVRE_MEMORY_OK`, `IA_LIVRE_AGENT_OK`.
//! Etapa 40: tool sandboxed `calc` + `IA_LIVRE_TOOL_SANDBOX_OK`.
//! Marcadores v1: `IA_LIVRE_MEMORY_POLICY_OK` (+ evidência de tools).
//! Ver docs/desenho-autonomia-v1.md e docs/autonomia-alem-v1.md.

mod calc;
mod repl;

use std::env;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode, Stdio};
use std::time::{SystemTime, UNIX_EPOCH};

const USAGE: &str = "\
Uso: ia-livre-agent [--model <path>] [--memory <path>] [--n-predict <n>] \\
                    [--runtime-bin <path>] [--prompt <texto>] \\
                    [--repl] [--repl-script <file>]

Autonomia v1+E40+E53 (camada 3) no host Linux.
Consome o runtime CPU (prova/--prompt); REPL sandboxed não exige inferência.
Não exige o SO IA Livre / QEMU / UEFI.
Allowlist: note / recall / help / calc. Ver docs/autonomia-repl.md.
";

const DEFAULT_MODEL: &str = "models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf";
const DEFAULT_MEMORY: &str = "build/agent-memory/memory.jsonl";
const DEFAULT_N_PREDICT: u32 = 16;
/// Prompt de prova alinhado ao runtime (Etapa 5 / E7).
const PROOF_PROMPT: &str = "Complete em uma frase: O Projeto IA Livre é";
/// Expressão canônica da prova `calc` (Etapa 40).
const PROOF_CALC_EXPR: &str = "1+2*3";
const PROOF_CALC_RESULT: f64 = 7.0;

/// Texto canônico gravado pela ferramenta `note` no cenário de prova.
const PROOF_NOTE: &str = "prova-autonomia-ia-livre";
/// Política de memória v1: últimas N entradas injetadas no prompt (fixado).
const MEMORY_POLICY_N: usize = 8;

struct Config {
    model: PathBuf,
    memory: PathBuf,
    n_predict: u32,
    runtime_bin: Option<PathBuf>,
    /// `None` = cenário de prova E7 (PROOF_PROMPT).
    prompt: Option<String>,
    repl: bool,
    repl_script: Option<PathBuf>,
}

fn parse_args() -> Result<Config, i32> {
    let args: Vec<String> = env::args().skip(1).collect();
    let mut model = PathBuf::from(DEFAULT_MODEL);
    let mut memory = PathBuf::from(DEFAULT_MEMORY);
    let mut n_predict = DEFAULT_N_PREDICT;
    let mut runtime_bin: Option<PathBuf> = None;
    let mut prompt: Option<String> = None;
    let mut repl = false;
    let mut repl_script: Option<PathBuf> = None;

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
            "--prompt" => {
                i += 1;
                let Some(v) = args.get(i) else {
                    eprintln!("erro: --prompt exige um texto");
                    return Err(2);
                };
                prompt = Some(v.clone());
            }
            "--repl" => {
                repl = true;
            }
            "--repl-script" => {
                i += 1;
                let Some(v) = args.get(i) else {
                    eprintln!("erro: --repl-script exige um arquivo");
                    return Err(2);
                };
                repl_script = Some(PathBuf::from(v));
            }
            other => {
                eprintln!("erro: argumento desconhecido: {other}");
                eprint!("{USAGE}");
                return Err(2);
            }
        }
        i += 1;
    }

    if prompt.is_some() && (repl || repl_script.is_some()) {
        eprintln!("erro: --prompt não combina com --repl / --repl-script");
        return Err(2);
    }

    Ok(Config {
        model,
        memory,
        n_predict,
        runtime_bin,
        prompt,
        repl,
        repl_script,
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

/// Lê linhas JSONL não vazias do store (kinds: note / turn / tool).
fn read_memory_lines(memory: &Path) -> Result<Vec<String>, String> {
    if !memory.is_file() {
        return Ok(Vec::new());
    }
    let raw = fs::read_to_string(memory)
        .map_err(|e| format!("ler memória {}: {e}", memory.display()))?;
    Ok(raw
        .lines()
        .map(str::trim)
        .filter(|l| !l.is_empty())
        .map(str::to_string)
        .collect())
}

/// Últimas N entradas (política v1; N=8 fixo).
fn last_n_entries(lines: &[String], n: usize) -> &[String] {
    if lines.len() <= n {
        lines
    } else {
        &lines[lines.len() - n..]
    }
}

/// Monta o prompt enviado ao runtime: contexto (últimas N) + texto do usuário/prova.
fn build_prompt_with_policy(user_text: &str, recent: &[String]) -> String {
    let mut out = String::new();
    out.push_str("Contexto (memória recente, até ");
    out.push_str(&MEMORY_POLICY_N.to_string());
    out.push_str(" entradas; kinds note/turn/tool):\n");
    if recent.is_empty() {
        out.push_str("(vazio)\n");
    } else {
        for (i, line) in recent.iter().enumerate() {
            out.push_str(&format!("{}. {}\n", i + 1, line));
        }
    }
    out.push('\n');
    out.push_str("Pedido:\n");
    out.push_str(user_text);
    out
}

/// Append genérico ao JSONL (só no path de memória documentado).
fn append_memory_line(memory: &Path, kind: &str, text: &str) -> Result<(), String> {
    ensure_parent_dir(memory)?;
    let line = format!(
        "{{\"ts\":{},\"kind\":\"{}\",\"text\":\"{}\"}}\n",
        unix_ts(),
        json_escape(kind),
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

/// Ferramenta `note`: appenda `{kind:"note", …}`.
pub(crate) fn tool_note(memory: &Path, text: &str) -> Result<(), String> {
    append_memory_line(memory, "note", text)
}

/// Ferramenta `recall`: lista até `n` entradas recentes (default N=8); registra kind `tool`.
pub(crate) fn tool_recall(memory: &Path, n: Option<usize>) -> Result<Vec<String>, String> {
    let limit = n.unwrap_or(MEMORY_POLICY_N);
    let lines = read_memory_lines(memory)?;
    let recent = last_n_entries(&lines, limit);
    let listed: Vec<String> = recent.to_vec();
    let summary = format!("recall n={} count={}", limit, listed.len());
    append_memory_line(memory, "tool", &summary)?;
    Ok(listed)
}

/// Ferramenta `help`: lista allowlist + contratos curtos; registra kind `tool`.
pub(crate) fn tool_help(memory: &Path) -> Result<&'static str, String> {
    const HELP: &str = "\
allowlist:
  note   — args: text; append kind=note ao JSONL
  recall — args: n opcional; lista entradas recentes do JSONL
  help   — lista ferramentas e contratos curtos
  calc   — args: expr; aritmética pura sandboxed (0-9 . + - * / ( ))
proibido: shell, HTTP, write fora do path de memória
";
    append_memory_line(memory, "tool", "help")?;
    Ok(HELP)
}

/// Ferramenta `calc`: avalia expressão aritmética sandboxed; registra kind `tool`.
pub(crate) fn tool_calc(memory: &Path, expr: &str) -> Result<f64, String> {
    let value = calc::eval_expr(expr)?;
    let summary = format!("calc: {expr} = {value}");
    append_memory_line(memory, "tool", &summary)?;
    Ok(value)
}

fn find_runtime_bin(explicit: Option<&Path>) -> Result<PathBuf, String> {
    if let Some(p) = explicit {
        if p.is_file() {
            return Ok(p.to_path_buf());
        }
        return Err(format!("--runtime-bin não encontrado: {}", p.display()));
    }

    let candidates = [
        PathBuf::from("target/debug/ia-livre-runtime"),
        PathBuf::from("target/release/ia-livre-runtime"),
    ];
    for c in &candidates {
        if c.is_file() {
            return Ok(c.clone());
        }
    }

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

fn invoke_runtime(config: &Config, prompt: &str) -> Result<String, String> {
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
        .arg(prompt)
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
    // 1) Carregar memória e aplicar política N=8 no prompt montado
    let lines = read_memory_lines(&config.memory)?;
    let recent = last_n_entries(&lines, MEMORY_POLICY_N);
    let user_text = config.prompt.as_deref().unwrap_or(PROOF_PROMPT);
    let mounted = build_prompt_with_policy(user_text, recent);
    println!("IA_LIVRE_MEMORY_POLICY_N={MEMORY_POLICY_N}");
    println!("IA_LIVRE_MEMORY_POLICY_OK");

    // 2–3) Runtime com prompt montado (prova E7 ou --prompt do usuário)
    let generated = invoke_runtime(config, &mounted)?;
    println!("IA_LIVRE_RUNTIME_USED=1");
    for line in generated.lines().take(8) {
        println!("runtime: {line}");
    }

    // 4–5) Prova v1 determinística: note + recall (≥2 tools; não depende do SLM)
    let mut tools_used: u32 = 0;

    tool_note(&config.memory, PROOF_NOTE)?;
    tools_used += 1;
    println!("IA_LIVRE_TOOL=note");

    let recalled = tool_recall(&config.memory, Some(MEMORY_POLICY_N))?;
    tools_used += 1;
    println!("IA_LIVRE_TOOL=recall");
    println!("IA_LIVRE_RECALL_COUNT={}", recalled.len());
    for (i, line) in recalled.iter().take(MEMORY_POLICY_N).enumerate() {
        println!("recall[{i}]: {line}");
    }

    let help_text = tool_help(&config.memory)?;
    tools_used += 1;
    println!("IA_LIVRE_TOOL=help");
    for line in help_text.lines().take(8) {
        println!("help: {line}");
    }

    // Etapa 40 — calc sandboxed (prova determinística)
    let calc_val = tool_calc(&config.memory, PROOF_CALC_EXPR)?;
    if (calc_val - PROOF_CALC_RESULT).abs() > 1e-9 {
        return Err(format!(
            "calc prova: esperado {PROOF_CALC_RESULT}, obtido {calc_val}"
        ));
    }
    tools_used += 1;
    println!("IA_LIVRE_TOOL=calc");
    println!("IA_LIVRE_CALC_RESULT={calc_val}");
    println!("calc: {PROOF_CALC_EXPR} = {calc_val}");
    // Rejeição rápida (charset) — prova negativa embutida
    if calc::eval_expr("1;rm").is_ok() {
        return Err("calc sandbox falhou: aceitou ';'".into());
    }
    println!("IA_LIVRE_TOOL_SANDBOX_OK");

    println!("IA_LIVRE_TOOLS_USED={tools_used}");
    if tools_used < 2 {
        return Err(format!(
            "prova v1 exige ≥2 ferramentas; obtido {tools_used}"
        ));
    }
    println!("IA_LIVRE_TOOL_OK");
    println!("IA_LIVRE_MEMORY_PATH={}", config.memory.display());

    // 6) Persistência verificável
    let stored = fs::read_to_string(&config.memory)
        .map_err(|e| format!("re-ler memória {}: {e}", config.memory.display()))?;
    if !stored.contains(PROOF_NOTE) {
        return Err(format!(
            "memória não contém a nota de prova `{PROOF_NOTE}` após escrita"
        ));
    }
    println!("IA_LIVRE_MEMORY_OK");

    // 7) Loop concluído
    println!("IA_LIVRE_AGENT_OK");

    Ok(())
}

fn main() -> ExitCode {
    let config = match parse_args() {
        Ok(c) => c,
        Err(0) => return ExitCode::SUCCESS,
        Err(_) => return ExitCode::from(2),
    };

    let result = if let Some(script) = &config.repl_script {
        repl::run_repl_scripted(&config.memory, script)
    } else if config.repl {
        repl::run_repl_interactive(&config.memory)
    } else {
        run(&config)
    };

    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("erro: {e}");
            ExitCode::from(1)
        }
    }
}
