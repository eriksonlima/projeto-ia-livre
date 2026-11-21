//! REPL sandboxed (Etapa 53): allowlist only; sem shell/HTTP.

use std::fs::File;
use std::io::{BufRead, BufReader, Write};
use std::path::Path;

use crate::{tool_calc, tool_help, tool_note, tool_recall};

pub fn run_repl_scripted(memory: &Path, script: &Path) -> Result<(), String> {
    println!("IA_LIVRE_REPL_MODE=scripted");
    let file = File::open(script).map_err(|e| format!("--repl-script {}: {e}", script.display()))?;
    let reader = BufReader::new(file);
    let mut tools = 0u32;
    for line in reader.lines() {
        let line = line.map_err(|e| format!("ler script: {e}"))?;
        match dispatch_line(memory, &line)? {
            LineResult::Continue { used_tool } => {
                if used_tool {
                    tools += 1;
                }
            }
            LineResult::Quit => break,
        }
    }
    if tools < 1 {
        return Err("REPL scripted: nenhuma tool da allowlist executada".into());
    }
    println!("IA_LIVRE_REPL_OK");
    Ok(())
}

pub fn run_repl_interactive(memory: &Path) -> Result<(), String> {
    println!("IA_LIVRE_REPL_MODE=interactive");
    let stdin = std::io::stdin();
    let mut stdout = std::io::stdout();
    let mut tools = 0u32;
    loop {
        write!(stdout, "ia-livre> ").map_err(|e| e.to_string())?;
        stdout.flush().map_err(|e| e.to_string())?;
        let mut line = String::new();
        let n = stdin.lock().read_line(&mut line).map_err(|e| e.to_string())?;
        if n == 0 {
            break;
        }
        match dispatch_line(memory, &line)? {
            LineResult::Continue { used_tool } => {
                if used_tool {
                    tools += 1;
                }
            }
            LineResult::Quit => break,
        }
    }
    if tools < 1 {
        return Err("REPL: nenhuma tool da allowlist executada".into());
    }
    println!("IA_LIVRE_REPL_OK");
    Ok(())
}

enum LineResult {
    Continue { used_tool: bool },
    Quit,
}

fn dispatch_line(memory: &Path, raw: &str) -> Result<LineResult, String> {
    let line = raw.trim();
    if line.is_empty() {
        return Ok(LineResult::Continue { used_tool: false });
    }
    let lower = line.to_ascii_lowercase();
    if lower == "quit" || lower == "exit" {
        return Ok(LineResult::Quit);
    }

    let mut parts = line.split_whitespace();
    let Some(cmd) = parts.next() else {
        return Ok(LineResult::Continue { used_tool: false });
    };
    let cmd_l = cmd.to_ascii_lowercase();

    match cmd_l.as_str() {
        "help" => {
            let text = tool_help(memory)?;
            print!("{text}");
            println!("IA_LIVRE_TOOL=help");
            Ok(LineResult::Continue { used_tool: true })
        }
        "note" => {
            let text = parts.collect::<Vec<_>>().join(" ");
            if text.is_empty() {
                return Err("note: exige texto".into());
            }
            tool_note(memory, &text)?;
            println!("IA_LIVRE_TOOL=note");
            Ok(LineResult::Continue { used_tool: true })
        }
        "recall" => {
            let n = parts.next().and_then(|s| s.parse::<usize>().ok());
            let listed = tool_recall(memory, n)?;
            println!("IA_LIVRE_TOOL=recall");
            println!("IA_LIVRE_RECALL_COUNT={}", listed.len());
            Ok(LineResult::Continue { used_tool: true })
        }
        "calc" => {
            let expr = parts.collect::<Vec<_>>().join(" ");
            if expr.is_empty() {
                return Err("calc: exige expressão".into());
            }
            let v = tool_calc(memory, &expr)?;
            println!("IA_LIVRE_TOOL=calc");
            println!("IA_LIVRE_CALC_RESULT={v}");
            println!("calc: {expr} = {v}");
            Ok(LineResult::Continue { used_tool: true })
        }
        other => Err(format!(
            "REPL: comando fora da allowlist: {other} (permitidos: note recall help calc quit)"
        )),
    }
}
