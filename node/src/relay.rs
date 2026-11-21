//! Relay TCP mínimo de introdução (Etapa 67) — sem forward de bytes de sessão.
//! RELAY_REG / RELAY_ASK / RELAY_HINT. Autenticação continua IDENT no dial direto.

use std::collections::HashSet;
use std::net::SocketAddr;
use std::sync::Arc;
use std::time::Duration;

use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::Mutex;

pub async fn run_relay_listen(port: u16) -> Result<(), String> {
    let listener = TcpListener::bind(SocketAddr::from(([0, 0, 0, 0], port)))
        .await
        .map_err(|e| format!("relay bind :{port}: {e}"))?;
    println!("IA_LIVRE_RELAY_LISTEN={port}");
    println!("IA_LIVRE_RELAY_MODE=intro");
    let peers: Arc<Mutex<HashSet<String>>> = Arc::new(Mutex::new(HashSet::new()));
    loop {
        let (stream, addr) = listener
            .accept()
            .await
            .map_err(|e| format!("relay accept: {e}"))?;
        let peers_c = peers.clone();
        tokio::spawn(async move {
            if let Err(e) = handle_relay_client(stream, peers_c).await {
                eprintln!("aviso: relay client {addr}: {e}");
            }
        });
    }
}

async fn handle_relay_client(
    stream: TcpStream,
    peers: Arc<Mutex<HashSet<String>>>,
) -> Result<(), String> {
    let (rd, mut wr) = stream.into_split();
    let mut lines = BufReader::new(rd).lines();
    while let Some(line) = lines
        .next_line()
        .await
        .map_err(|e| format!("read: {e}"))?
    {
        let line = line.trim().to_string();
        if line.is_empty() {
            continue;
        }
        if let Some(ep) = line.strip_prefix("RELAY_REG v1 ") {
            let ep = ep.trim().to_string();
            if ep.parse::<SocketAddr>().is_err() {
                wr.write_all(b"RELAY_ERR bad_endpoint\n")
                    .await
                    .map_err(|e| format!("write: {e}"))?;
                continue;
            }
            peers.lock().await.insert(ep);
            wr.write_all(b"RELAY_ACK\n")
                .await
                .map_err(|e| format!("write: {e}"))?;
        } else if line == "RELAY_ASK v1" {
            let list: Vec<String> = peers.lock().await.iter().cloned().collect();
            if let Some(hint) = list.first() {
                let msg = format!("RELAY_HINT v1 {hint}\n");
                wr.write_all(msg.as_bytes())
                    .await
                    .map_err(|e| format!("write: {e}"))?;
            } else {
                wr.write_all(b"RELAY_EMPTY\n")
                    .await
                    .map_err(|e| format!("write: {e}"))?;
            }
        } else {
            wr.write_all(b"RELAY_ERR unknown\n")
                .await
                .map_err(|e| format!("write: {e}"))?;
        }
    }
    Ok(())
}

/// Registra `advertised` no relay e retorna.
pub async fn register_with_relay(relay: &str, advertised: &str) -> Result<(), String> {
    let addr: SocketAddr = relay
        .parse()
        .map_err(|_| format!("--relay-reg inválido: {relay}"))?;
    let mut last = None;
    for _ in 0..40 {
        match TcpStream::connect(addr).await {
            Ok(mut stream) => {
                let msg = format!("RELAY_REG v1 {advertised}\n");
                stream
                    .write_all(msg.as_bytes())
                    .await
                    .map_err(|e| format!("relay reg write: {e}"))?;
                let mut line = String::new();
                let mut rd = BufReader::new(stream);
                rd.read_line(&mut line)
                    .await
                    .map_err(|e| format!("relay reg read: {e}"))?;
                if line.trim() == "RELAY_ACK" {
                    println!("IA_LIVRE_RELAY_REG_OK");
                    return Ok(());
                }
                return Err(format!("relay reg resposta: {}", line.trim()));
            }
            Err(e) => {
                last = Some(e.to_string());
                tokio::time::sleep(Duration::from_millis(100)).await;
            }
        }
    }
    Err(format!(
        "relay reg falhou: {}",
        last.unwrap_or_else(|| "timeout".into())
    ))
}

/// Pergunta hint ao relay; `Ok(Some(ep))` ou `Ok(None)` se vazio.
pub async fn ask_relay_hint(relay: &str) -> Result<Option<String>, String> {
    let addr: SocketAddr = relay
        .parse()
        .map_err(|_| format!("--relay inválido: {relay}"))?;
    let mut last = None;
    for _ in 0..40 {
        match TcpStream::connect(addr).await {
            Ok(mut stream) => {
                stream
                    .write_all(b"RELAY_ASK v1\n")
                    .await
                    .map_err(|e| format!("relay ask write: {e}"))?;
                let mut line = String::new();
                let mut rd = BufReader::new(stream);
                rd.read_line(&mut line)
                    .await
                    .map_err(|e| format!("relay ask read: {e}"))?;
                let t = line.trim();
                if let Some(ep) = t.strip_prefix("RELAY_HINT v1 ") {
                    return Ok(Some(ep.trim().to_string()));
                }
                if t == "RELAY_EMPTY" {
                    return Ok(None);
                }
                return Err(format!("relay ask resposta: {t}"));
            }
            Err(e) => {
                last = Some(e.to_string());
                tokio::time::sleep(Duration::from_millis(100)).await;
            }
        }
    }
    Err(format!(
        "relay ask falhou: {}",
        last.unwrap_or_else(|| "timeout".into())
    ))
}
