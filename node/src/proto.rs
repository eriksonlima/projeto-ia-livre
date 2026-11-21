//! Framing Rede IA Livre v1 (linhas UTF-8).

use crate::identity::{peer_id_matches_pubkey, sign, verify_sig};
use ed25519_dalek::SigningKey;
use rand::RngCore;

pub const PROTO_V: &str = "v1";
pub const PROOF_TEXT: &str = "ola-rede-ia-livre";

/// Mensagem canônica HELLO (o que a assinatura cobre).
pub fn hello_canonical(peer_id: &str, tcp_port: u16, pubkey_hex: &str) -> String {
    format!("HELLO|{PROTO_V}|{peer_id}|{tcp_port}|{pubkey_hex}")
}

pub fn format_hello(sk: &SigningKey, peer_id: &str, tcp_port: u16, pubkey_hex: &str) -> String {
    let canon = hello_canonical(peer_id, tcp_port, pubkey_hex);
    let sig = sign(sk, canon.as_bytes());
    format!("HELLO {PROTO_V} {peer_id} {tcp_port} {pubkey_hex} {sig}\n")
}

#[derive(Debug, Clone)]
pub struct HelloV1 {
    pub peer_id: String,
    pub tcp_port: u16,
    #[allow(dead_code)]
    pub pubkey_hex: String,
}

/// Parse + valida HELLO v1 assinado. Retorna None se inválido.
pub fn parse_hello_v1(line: &str) -> Option<HelloV1> {
    let rest = line.strip_prefix("HELLO ")?;
    let mut parts = rest.split_whitespace();
    let ver = parts.next()?;
    if ver != PROTO_V {
        return None;
    }
    let peer_id = parts.next()?.to_string();
    let port_raw = parts.next()?;
    let pubkey_hex = parts.next()?.to_string();
    let sig_hex = parts.next()?;
    if parts.next().is_some() {
        return None;
    }
    let tcp_port: u16 = port_raw.parse().ok()?;
    if tcp_port == 0 {
        return None;
    }
    if !peer_id_matches_pubkey(&peer_id, &pubkey_hex) {
        return None;
    }
    let canon = hello_canonical(&peer_id, tcp_port, &pubkey_hex);
    if !verify_sig(&pubkey_hex, canon.as_bytes(), sig_hex) {
        return None;
    }
    Some(HelloV1 {
        peer_id,
        tcp_port,
        pubkey_hex,
    })
}

pub fn ident_canonical(peer_id: &str, pubkey_hex: &str, nonce_hex: &str) -> String {
    format!("IDENT|{PROTO_V}|{peer_id}|{pubkey_hex}|{nonce_hex}")
}

pub fn format_ident(sk: &SigningKey, peer_id: &str, pubkey_hex: &str, nonce_hex: &str) -> String {
    let canon = ident_canonical(peer_id, pubkey_hex, nonce_hex);
    let sig = sign(sk, canon.as_bytes());
    format!("IDENT {PROTO_V} {peer_id} {pubkey_hex} {nonce_hex} {sig}\n")
}

#[derive(Debug, Clone)]
pub struct IdentV1 {
    pub peer_id: String,
    #[allow(dead_code)]
    pub pubkey_hex: String,
    #[allow(dead_code)]
    pub nonce_hex: String,
}

pub fn parse_ident_v1(line: &str) -> Option<IdentV1> {
    let rest = line.strip_prefix("IDENT ")?;
    let mut parts = rest.split_whitespace();
    let ver = parts.next()?;
    if ver != PROTO_V {
        return None;
    }
    let peer_id = parts.next()?.to_string();
    let pubkey_hex = parts.next()?.to_string();
    let nonce_hex = parts.next()?.to_string();
    let sig_hex = parts.next()?;
    if parts.next().is_some() {
        return None;
    }
    if !peer_id_matches_pubkey(&peer_id, &pubkey_hex) {
        return None;
    }
    let canon = ident_canonical(&peer_id, &pubkey_hex, &nonce_hex);
    if !verify_sig(&pubkey_hex, canon.as_bytes(), sig_hex) {
        return None;
    }
    Some(IdentV1 {
        peer_id,
        pubkey_hex,
        nonce_hex,
    })
}

pub fn random_nonce_hex() -> String {
    let mut buf = [0u8; 16];
    rand::thread_rng().fill_bytes(&mut buf);
    hex::encode(buf)
}

pub fn format_msg(text: &str) -> String {
    format!("MSG {text}\n")
}

pub fn format_ack(text: &str) -> String {
    format!("ACK {text}\n")
}

pub fn format_ping(nonce_hex: &str) -> String {
    format!("PING {nonce_hex}\n")
}

pub fn format_pong(nonce_hex: &str) -> String {
    format!("PONG {nonce_hex}\n")
}
