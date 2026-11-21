//! CLI do protótipo de runtime de inferência (Etapa 5 CPU + Etapa 8 GPU opcional).
//! Carrega um GGUF no host, gera texto e emite métricas básicas grepáveis.

use llama_cpp_2::context::params::LlamaContextParams;
use llama_cpp_2::llama_backend::LlamaBackend;
use llama_cpp_2::llama_batch::LlamaBatch;
use llama_cpp_2::model::params::LlamaModelParams;
use llama_cpp_2::model::LlamaModel;
use llama_cpp_2::sampling::LlamaSampler;

use std::env;
use std::io::{self, Write};
use std::num::NonZeroU32;
use std::path::PathBuf;
use std::process::ExitCode;
use std::time::Instant;

/// Prompt canônico da Etapa 5 (gate e métricas usam o mesmo texto).
const DEFAULT_PROMPT: &str = "Complete em uma frase: O Projeto IA Livre é";

/// Tokens de saída (além do prompt). Baixo de propósito para o protótipo.
const DEFAULT_N_PREDICT: i32 = 48;

/// Default = CPU (Etapa 5). N > 0 pede offload GPU (Etapa 8; requer feature cuda|vulkan).
const DEFAULT_N_GPU_LAYERS: u32 = 0;

const USAGE: &str = "\
Uso: ia-livre-runtime --model <caminho.gguf> [--prompt <texto>] [--n-predict <n>] [--n-gpu-layers <n>]

Carrega o GGUF (llama.cpp) e imprime o texto gerado na stdout.
--n-gpu-layers: default 0 = CPU; N > 0 = offload (requer build com --features cuda|vulkan).
Prompt padrão (fixado): \"Complete em uma frase: O Projeto IA Livre é\"
Métricas: IA_LIVRE_LOAD_S=… IA_LIVRE_TOKENS_PER_S=… IA_LIVRE_INFER_OK
Aceleração: IA_LIVRE_ACCEL=… IA_LIVRE_N_GPU_LAYERS=…
";

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(code) => code,
    }
}

fn run() -> Result<(), ExitCode> {
    let args: Vec<String> = env::args().skip(1).collect();
    let mut model: Option<PathBuf> = None;
    let mut prompt = DEFAULT_PROMPT.to_string();
    let mut n_predict = DEFAULT_N_PREDICT;
    let mut n_gpu_layers = DEFAULT_N_GPU_LAYERS;

    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "-h" | "--help" => {
                print!("{USAGE}");
                return Ok(());
            }
            "--model" => {
                i += 1;
                let Some(path) = args.get(i) else {
                    eprintln!("erro: --model exige um caminho");
                    return Err(ExitCode::from(2));
                };
                model = Some(PathBuf::from(path));
            }
            "--prompt" => {
                i += 1;
                let Some(text) = args.get(i) else {
                    eprintln!("erro: --prompt exige um texto");
                    return Err(ExitCode::from(2));
                };
                prompt = text.clone();
            }
            "--n-predict" => {
                i += 1;
                let Some(raw) = args.get(i) else {
                    eprintln!("erro: --n-predict exige um inteiro");
                    return Err(ExitCode::from(2));
                };
                n_predict = raw.parse().map_err(|_| {
                    eprintln!("erro: --n-predict inválido: {raw}");
                    ExitCode::from(2)
                })?;
                if n_predict < 1 {
                    eprintln!("erro: --n-predict deve ser >= 1");
                    return Err(ExitCode::from(2));
                }
            }
            "--n-gpu-layers" => {
                i += 1;
                let Some(raw) = args.get(i) else {
                    eprintln!("erro: --n-gpu-layers exige um inteiro >= 0");
                    return Err(ExitCode::from(2));
                };
                n_gpu_layers = raw.parse().map_err(|_| {
                    eprintln!("erro: --n-gpu-layers inválido: {raw}");
                    ExitCode::from(2)
                })?;
            }
            other => {
                eprintln!("erro: argumento desconhecido: {other}");
                eprint!("{USAGE}");
                return Err(ExitCode::from(2));
            }
        }
        i += 1;
    }

    let Some(model_path) = model else {
        eprintln!("erro: informe --model <caminho.gguf>");
        eprint!("{USAGE}");
        return Err(ExitCode::from(2));
    };

    if !model_path.is_file() {
        eprintln!(
            "erro: modelo não encontrado: {}\n\
             Baixe com: ./scripts/fetch-model.sh\n\
             Path padrão: models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
            model_path.display()
        );
        return Err(ExitCode::from(1));
    }

    if let Err(e) = infer(&model_path, &prompt, n_predict, n_gpu_layers) {
        eprintln!("erro: {e}");
        return Err(ExitCode::from(1));
    }
    Ok(())
}

/// Backend de aceleração refletido em `IA_LIVRE_ACCEL=` (compilação + pedido de layers).
fn accel_label(n_gpu_layers: u32) -> &'static str {
    if n_gpu_layers == 0 {
        return "cpu";
    }
    if cfg!(feature = "cuda") {
        "cuda"
    } else if cfg!(feature = "vulkan") {
        "vulkan"
    } else {
        // Pediu offload sem feature GPU: ainda CPU (llama.cpp ignora layers sem backend).
        "cpu"
    }
}

fn infer(
    model_path: &std::path::Path,
    prompt: &str,
    n_predict: i32,
    n_gpu_layers: u32,
) -> Result<(), String> {
    let backend = LlamaBackend::init().map_err(|e| format!("init backend: {e}"))?;

    let model_params = LlamaModelParams::default().with_n_gpu_layers(n_gpu_layers);
    let accel = accel_label(n_gpu_layers);

    if n_gpu_layers > 0 && accel == "cpu" {
        eprintln!(
            "aviso: --n-gpu-layers={n_gpu_layers} mas o binário foi buildado sem --features cuda|vulkan; \
             offload efetivo permanece CPU (IA_LIVRE_ACCEL=cpu). Ver ADR 0002 / AGENTS.md."
        );
    }

    let t_load = Instant::now();
    let model = LlamaModel::load_from_file(&backend, model_path, &model_params)
        .map_err(|e| format!("load model {}: {e}", model_path.display()))?;

    let ctx_params = LlamaContextParams::default()
        .with_n_ctx(Some(NonZeroU32::new(512).expect("512 != 0")));

    let mut ctx = model
        .new_context(&backend, ctx_params)
        .map_err(|e| format!("new context: {e}"))?;
    let load_s = t_load.elapsed().as_secs_f64();

    let tokens_list = model.vocab().tokenize(prompt.as_bytes(), true, true);

    if env::var_os("IA_LIVRE_DUMP_TOKEN_IDS").is_some() {
        let ids: Vec<i32> = tokens_list.iter().map(|t| t.0).collect();
        println!("IA_LIVRE_TOKEN_IDS={ids:?}");
        println!("IA_LIVRE_TOKEN_N={}", ids.len());
        return Ok(());
    }

    let n_ctx = ctx.n_ctx() as i32;
    let n_prompt = tokens_list.len() as i32;
    let n_len = n_prompt + n_predict;
    if n_len > n_ctx {
        return Err(format!(
            "prompt+predict ({n_len}) excede n_ctx ({n_ctx}); reduza --n-predict"
        ));
    }
    if tokens_list.is_empty() {
        return Err("prompt tokenizado ficou vazio".into());
    }

    let mut batch = LlamaBatch::new(512, 1);
    let last_index = (tokens_list.len() - 1) as i32;
    for (i, token) in (0_i32..).zip(tokens_list.into_iter()) {
        let is_last = i == last_index;
        batch
            .add(token, i, &[0], is_last)
            .map_err(|e| format!("batch.add prompt: {e}"))?;
    }

    ctx.decode(&mut batch)
        .map_err(|e| format!("decode prompt: {e}"))?;

    let mut sampler = LlamaSampler::chain_simple([LlamaSampler::greedy()]);
    let mut n_cur = batch.n_tokens();
    let mut generated = String::new();
    let mut n_decode: u32 = 0;

    let t_gen = Instant::now();
    while n_cur < n_len {
        let token = sampler.sample(&ctx, batch.n_tokens() - 1);
        sampler.accept(token);

        if model.vocab().is_eog(token) {
            break;
        }

        let piece = model.vocab().token_to_piece(token, true, None);
        let chunk = String::from_utf8_lossy(&piece);
        print!("{chunk}");
        let _ = io::stdout().flush();
        generated.push_str(&chunk);

        batch.clear();
        batch
            .add(token, n_cur, &[0], true)
            .map_err(|e| format!("batch.add gen: {e}"))?;
        ctx.decode(&mut batch)
            .map_err(|e| format!("decode gen: {e}"))?;
        n_cur += 1;
        n_decode += 1;
    }
    let gen_s = t_gen.elapsed().as_secs_f64();
    let tokens_per_s = if gen_s > 0.0 {
        f64::from(n_decode) / gen_s
    } else {
        0.0
    };

    if !generated.ends_with('\n') {
        println!();
    }

    println!("IA_LIVRE_INFER_OK");
    println!("IA_LIVRE_LOAD_S={load_s:.3}");
    println!("IA_LIVRE_TOKENS_PER_S={tokens_per_s:.3}");
    println!("IA_LIVRE_N_DECODE={n_decode}");
    println!("IA_LIVRE_ACCEL={accel}");
    println!("IA_LIVRE_N_GPU_LAYERS={n_gpu_layers}");
    println!("model={}", model_path.display());
    println!("prompt={prompt}");
    Ok(())
}
