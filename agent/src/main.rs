//! CLI do protótipo do ambiente de autonomia (Etapa 7).
//! Scaffold: parse de flags; loop completo (runtime + ferramenta + memória) nas fatias seguintes.
//! Ver docs/ambiente-autonomia-prototipo.md.

use std::env;
use std::path::PathBuf;
use std::process::ExitCode;

const USAGE: &str = "\
Uso: ia-livre-agent [--model <path>] [--memory <path>] [--n-predict <n>]

Protótipo da camada 3 (autonomia) no host Linux.
Consome o runtime CPU existente; não exige o SO IA Livre / QEMU / UEFI.
Ver docs/ambiente-autonomia-prototipo.md.
";

const DEFAULT_MODEL: &str = "models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf";
const DEFAULT_MEMORY: &str = "build/agent-memory/memory.jsonl";
const DEFAULT_N_PREDICT: u32 = 16;

struct Config {
    model: PathBuf,
    memory: PathBuf,
    n_predict: u32,
}

fn parse_args() -> Result<Config, i32> {
    let args: Vec<String> = env::args().skip(1).collect();
    let mut model = PathBuf::from(DEFAULT_MODEL);
    let mut memory = PathBuf::from(DEFAULT_MEMORY);
    let mut n_predict = DEFAULT_N_PREDICT;

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
    })
}

fn main() -> ExitCode {
    let config = match parse_args() {
        Ok(c) => c,
        Err(0) => return ExitCode::SUCCESS,
        Err(_) => return ExitCode::from(2),
    };

    println!("IA_LIVRE_AGENT_SCAFFOLD_OK");
    println!("IA_LIVRE_MODEL={}", config.model.display());
    println!("IA_LIVRE_MEMORY_PATH={}", config.memory.display());
    println!("IA_LIVRE_N_PREDICT={}", config.n_predict);
    println!(
        "nota: loop completo (runtime + ferramenta + memória) nas próximas fatias; \
         ver docs/ambiente-autonomia-prototipo.md"
    );

    ExitCode::SUCCESS
}
