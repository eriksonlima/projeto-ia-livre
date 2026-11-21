//! Sessão TCP v1: IDENT ↔ IDENT → MSG/ACK → PING/PONG → TASK/TASK_ACK → KNOW/KNOW_ACK.

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use ed25519_dalek::SigningKey;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::TcpStream;

use crate::proto::{
    format_ack, format_ident, format_know, format_know_ack, format_msg, format_ping, format_pong,
    format_task, format_task_ack, parse_ident_v1, parse_know, parse_know_ack, parse_task,
    parse_task_ack, random_nonce_hex, PROOF_KNOW_ID, PROOF_KNOW_TEXT, PROOF_TASK_ID, PROOF_TASK_TEXT,
    PROOF_TEXT,
};

pub fn emit_peer_ok(peer_ok: &AtomicBool, addr: std::net::SocketAddr) -> bool {
    if peer_ok
        .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
        .is_ok()
    {
        println!("IA_LIVRE_PEER_OK");
        println!("IA_LIVRE_PEER_ADDR={addr}");
        true
    } else {
        false
    }
}

fn emit_once(flag: &mut bool, marker: &str) {
    if !*flag {
        println!("{marker}");
        *flag = true;
    }
}

/// Handshake IDENT + prova MSG/ACK + PING/PONG + TASK/TASK_ACK + KNOW/KNOW_ACK.
pub async fn run_session(
    stream: TcpStream,
    sk: SigningKey,
    peer_id: String,
    pubkey_hex: String,
    remote_hint: std::net::SocketAddr,
    peer_ok: Arc<AtomicBool>,
) {
    let (read_half, mut write_half) = stream.into_split();
    let mut reader = BufReader::new(read_half);

    let our_nonce = random_nonce_hex();
    let outbound_ident = format_ident(&sk, &peer_id, &pubkey_hex, &our_nonce);
    if write_half
        .write_all(outbound_ident.as_bytes())
        .await
        .is_err()
    {
        return;
    }
    let _ = write_half.flush().await;

    // Espera IDENT do peer.
    let mut line = String::new();
    let peer_ident = loop {
        line.clear();
        match reader.read_line(&mut line).await {
            Ok(0) => return,
            Ok(_) => {
                let trimmed = line.trim_end_matches(['\r', '\n']);
                if trimmed.is_empty() {
                    continue;
                }
                match parse_ident_v1(trimmed) {
                    Some(id) => {
                        if id.peer_id == peer_id {
                            continue;
                        }
                        break id;
                    }
                    None => {
                        eprintln!("aviso: IDENT inválido de {remote_hint}");
                        return;
                    }
                }
            }
            Err(_) => return,
        }
    };

    println!("IA_LIVRE_IDENT_OK");
    println!("IA_LIVRE_REMOTE_PEER_ID={}", peer_ident.peer_id);

    if !emit_peer_ok(&peer_ok, remote_hint) {
        // Outro caminho já emitiu; ainda assim completamos a prova.
    }

    let outbound = format_msg(PROOF_TEXT);
    if write_half.write_all(outbound.as_bytes()).await.is_err() {
        return;
    }
    let _ = write_half.flush().await;

    let mut msg_ok = false;
    let mut ping_ok = false;
    let mut task_ok = false;
    let mut know_ok = false;
    let ping_nonce = random_nonce_hex();
    let mut ping_sent = false;
    let mut task_sent = false;
    let mut know_sent = false;

    loop {
        line.clear();
        match reader.read_line(&mut line).await {
            Ok(0) => break,
            Ok(_) => {
                let trimmed = line.trim_end_matches(['\r', '\n']);
                if trimmed.is_empty() {
                    continue;
                }
                if let Some(text) = trimmed.strip_prefix("MSG ") {
                    if text == PROOF_TEXT {
                        let ack = format_ack(PROOF_TEXT);
                        if write_half.write_all(ack.as_bytes()).await.is_err() {
                            break;
                        }
                        let _ = write_half.flush().await;
                        emit_once(&mut msg_ok, "IA_LIVRE_MSG_OK");
                    }
                } else if let Some(text) = trimmed.strip_prefix("ACK ") {
                    if text == PROOF_TEXT {
                        emit_once(&mut msg_ok, "IA_LIVRE_MSG_OK");
                    }
                } else if let Some(nonce) = trimmed.strip_prefix("PING ") {
                    let pong = format_pong(nonce.trim());
                    if write_half.write_all(pong.as_bytes()).await.is_err() {
                        break;
                    }
                    let _ = write_half.flush().await;
                } else if let Some(nonce) = trimmed.strip_prefix("PONG ") {
                    if nonce.trim() == ping_nonce {
                        emit_once(&mut ping_ok, "IA_LIVRE_PING_OK");
                    }
                } else if let Some((tid, text)) = parse_task(trimmed) {
                    if tid == PROOF_TASK_ID && text == PROOF_TASK_TEXT {
                        let ack = format_task_ack(tid);
                        if write_half.write_all(ack.as_bytes()).await.is_err() {
                            break;
                        }
                        let _ = write_half.flush().await;
                        emit_once(&mut task_ok, "IA_LIVRE_TASK_OK");
                    }
                } else if let Some(tid) = parse_task_ack(trimmed) {
                    if tid == PROOF_TASK_ID {
                        emit_once(&mut task_ok, "IA_LIVRE_TASK_OK");
                    }
                } else if let Some((kid, text)) = parse_know(trimmed) {
                    if kid == PROOF_KNOW_ID && text == PROOF_KNOW_TEXT {
                        let ack = format_know_ack(kid);
                        if write_half.write_all(ack.as_bytes()).await.is_err() {
                            break;
                        }
                        let _ = write_half.flush().await;
                        emit_once(&mut know_ok, "IA_LIVRE_KNOW_OK");
                    }
                } else if let Some(kid) = parse_know_ack(trimmed) {
                    if kid == PROOF_KNOW_ID {
                        emit_once(&mut know_ok, "IA_LIVRE_KNOW_OK");
                    }
                } else if trimmed.starts_with("IDENT ") {
                    continue;
                }

                if msg_ok && !ping_sent {
                    let ping = format_ping(&ping_nonce);
                    if write_half.write_all(ping.as_bytes()).await.is_err() {
                        break;
                    }
                    let _ = write_half.flush().await;
                    ping_sent = true;
                }

                if msg_ok && ping_ok && !task_sent {
                    let task = format_task(PROOF_TASK_ID, PROOF_TASK_TEXT);
                    if write_half.write_all(task.as_bytes()).await.is_err() {
                        break;
                    }
                    let _ = write_half.flush().await;
                    task_sent = true;
                }

                if msg_ok && ping_ok && task_ok && !know_sent {
                    let know = format_know(PROOF_KNOW_ID, PROOF_KNOW_TEXT);
                    if write_half.write_all(know.as_bytes()).await.is_err() {
                        break;
                    }
                    let _ = write_half.flush().await;
                    know_sent = true;
                }

                if msg_ok && ping_ok && task_ok && know_ok {
                    tokio::time::sleep(std::time::Duration::from_millis(200)).await;
                    break;
                }
            }
            Err(_) => break,
        }
    }
}
