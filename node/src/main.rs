//! CLI do protótipo do nó Rede IA Livre (Etapa 6).
//! Descoberta UDP HELLO / `--peer` + sessão TCP + MSG/ACK de prova.
//! Marcadores: `IA_LIVRE_PEER_OK`, `IA_LIVRE_MSG_OK`.

use std::env;
use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4};
use std::process::ExitCode;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

use socket2::{Domain, Protocol, Socket, Type};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{TcpListener, TcpStream, UdpSocket};
use tokio::time::interval;

const USAGE: &str = "\
Uso: ia-livre-node [--node-id <id>] [--tcp-port <porta>] [--udp-port <porta>] [--peer <host:port>]

Sobe um nó: listen TCP, anúncio UDP HELLO (descoberta) e/ou dial via --peer.
Após sessão TCP: MSG/ACK da mensagem de prova (ola-rede-ia-livre).
Marcadores: IA_LIVRE_PEER_OK, IA_LIVRE_MSG_OK.
Ver docs/rede-ia-livre-prototipo.md.
";

/// Texto canônico da mensagem de prova (gate / protocolo).
const PROOF_TEXT: &str = "ola-rede-ia-livre";

struct Config {
    node_id: String,
    tcp_port: u16,
    udp_port: u16,
    peer: Option<String>,
}

fn parse_args() -> Result<Config, i32> {
    let args: Vec<String> = env::args().skip(1).collect();
    let mut node_id: Option<String> = None;
    let mut tcp_port: u16 = 7400;
    let mut udp_port: u16 = 7410;
    let mut peer: Option<String> = None;

    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "-h" | "--help" => {
                print!("{USAGE}");
                return Err(0);
            }
            "--node-id" => {
                i += 1;
                let Some(v) = args.get(i) else {
                    eprintln!("erro: --node-id exige um valor");
                    return Err(2);
                };
                node_id = Some(v.clone());
            }
            "--tcp-port" => {
                i += 1;
                let Some(raw) = args.get(i) else {
                    eprintln!("erro: --tcp-port exige uma porta");
                    return Err(2);
                };
                match raw.parse::<u16>() {
                    Ok(p) if p > 0 => tcp_port = p,
                    _ => {
                        eprintln!("erro: --tcp-port inválido: {raw}");
                        return Err(2);
                    }
                }
            }
            "--udp-port" => {
                i += 1;
                let Some(raw) = args.get(i) else {
                    eprintln!("erro: --udp-port exige uma porta");
                    return Err(2);
                };
                match raw.parse::<u16>() {
                    Ok(p) if p > 0 => udp_port = p,
                    _ => {
                        eprintln!("erro: --udp-port inválido: {raw}");
                        return Err(2);
                    }
                }
            }
            "--peer" => {
                i += 1;
                let Some(v) = args.get(i) else {
                    eprintln!("erro: --peer exige host:port");
                    return Err(2);
                };
                peer = Some(v.clone());
            }
            other => {
                eprintln!("erro: argumento desconhecido: {other}");
                eprint!("{USAGE}");
                return Err(2);
            }
        }
        i += 1;
    }

    let node_id = node_id.unwrap_or_else(|| format!("node-{}", std::process::id()));
    Ok(Config {
        node_id,
        tcp_port,
        udp_port,
        peer,
    })
}

fn emit_peer_ok(peer_ok: &AtomicBool, addr: SocketAddr) -> bool {
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

fn emit_msg_ok(msg_ok: &mut bool) {
    if !*msg_ok {
        println!("IA_LIVRE_MSG_OK");
        *msg_ok = true;
    }
}

/// Sessão TCP: envia MSG de prova, responde ACK e emite `IA_LIVRE_MSG_OK`.
async fn run_session(stream: TcpStream) {
    let (read_half, mut write_half) = stream.into_split();
    let mut reader = BufReader::new(read_half);

    let outbound = format!("MSG {PROOF_TEXT}\n");
    if write_half.write_all(outbound.as_bytes()).await.is_err() {
        return;
    }
    let _ = write_half.flush().await;

    let mut msg_ok = false;
    let mut line = String::new();
    loop {
        line.clear();
        match reader.read_line(&mut line).await {
            Ok(0) => break,
            Ok(_) => {
                let trimmed = line.trim_end_matches(['\r', '\n']);
                if let Some(text) = trimmed.strip_prefix("MSG ") {
                    if text == PROOF_TEXT {
                        let ack = format!("ACK {PROOF_TEXT}\n");
                        if write_half.write_all(ack.as_bytes()).await.is_err() {
                            break;
                        }
                        let _ = write_half.flush().await;
                        emit_msg_ok(&mut msg_ok);
                    }
                } else if let Some(text) = trimmed.strip_prefix("ACK ") {
                    if text == PROOF_TEXT {
                        // Preferencialmente ambos emitem MSG_OK (receptor do MSG já emitiu;
                        // o remetente confirma via ACK).
                        emit_msg_ok(&mut msg_ok);
                    }
                }
            }
            Err(_) => break,
        }
    }
}

fn bind_udp_reuse(port: u16) -> std::io::Result<UdpSocket> {
    let socket = Socket::new(Domain::IPV4, Type::DGRAM, Some(Protocol::UDP))?;
    socket.set_reuse_address(true)?;
    #[cfg(unix)]
    socket.set_reuse_port(true)?;
    socket.set_broadcast(true)?;
    let addr = SocketAddrV4::new(Ipv4Addr::UNSPECIFIED, port);
    socket.bind(&socket2::SockAddr::from(addr))?;
    socket.set_nonblocking(true)?;
    let std_sock: std::net::UdpSocket = socket.into();
    UdpSocket::from_std(std_sock)
}

async fn run_udp_discovery(
    node_id: String,
    tcp_port: u16,
    udp_port: u16,
    peer_ok: Arc<AtomicBool>,
    dialing: Arc<AtomicBool>,
) {
    let sock = match bind_udp_reuse(udp_port) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("aviso: UDP descoberta indisponível ({e}); use --peer");
            return;
        }
    };

    let hello = format!("HELLO {node_id} {tcp_port}\n");
    let targets = [
        SocketAddr::from((Ipv4Addr::LOCALHOST, udp_port)),
        SocketAddr::from((Ipv4Addr::BROADCAST, udp_port)),
    ];

    let mut tick = interval(Duration::from_secs(1));
    let mut buf = [0u8; 512];

    loop {
        tokio::select! {
            _ = tick.tick() => {
                if peer_ok.load(Ordering::SeqCst) {
                    continue;
                }
                for dest in targets {
                    let _ = sock.send_to(hello.as_bytes(), dest).await;
                }
            }
            result = sock.recv_from(&mut buf) => {
                let Ok((n, src)) = result else { continue };
                if peer_ok.load(Ordering::SeqCst) {
                    continue;
                }
                let text = String::from_utf8_lossy(&buf[..n]);
                let line = text.trim();
                let Some(rest) = line.strip_prefix("HELLO ") else { continue };
                let mut parts = rest.split_whitespace();
                let Some(peer_id) = parts.next() else { continue };
                let Some(port_raw) = parts.next() else { continue };
                if peer_id == node_id {
                    continue;
                }
                let Ok(peer_tcp) = port_raw.parse::<u16>() else { continue };
                if peer_tcp == 0 {
                    continue;
                }
                if dialing
                    .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
                    .is_err()
                {
                    continue;
                }
                let dial_addr = SocketAddr::new(src.ip(), peer_tcp);
                let peer_ok_c = peer_ok.clone();
                let dialing_c = dialing.clone();
                tokio::spawn(async move {
                    match TcpStream::connect(dial_addr).await {
                        Ok(stream) => {
                            if emit_peer_ok(&peer_ok_c, dial_addr) {
                                run_session(stream).await;
                            }
                        }
                        Err(e) => {
                            eprintln!("aviso: dial UDP→TCP {dial_addr} falhou: {e}");
                            dialing_c.store(false, Ordering::SeqCst);
                        }
                    }
                });
            }
        }
    }
}

async fn dial_peer(peer: String, peer_ok: Arc<AtomicBool>, dialing: Arc<AtomicBool>) {
    // Pequena espera para o outro processo bindar o listen TCP.
    tokio::time::sleep(Duration::from_millis(300)).await;

    let addr: SocketAddr = match peer.parse() {
        Ok(a) => a,
        Err(_) => {
            eprintln!("erro: --peer inválido (use host:port): {peer}");
            return;
        }
    };

    for attempt in 1..=30 {
        if peer_ok.load(Ordering::SeqCst) {
            return;
        }
        if dialing
            .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
            .is_err()
        {
            // Outro caminho (UDP) já está dialando; ainda tentamos depois se falhar.
            tokio::time::sleep(Duration::from_millis(200)).await;
            continue;
        }
        match TcpStream::connect(addr).await {
            Ok(stream) => {
                if emit_peer_ok(&peer_ok, addr) {
                    run_session(stream).await;
                }
                return;
            }
            Err(e) => {
                dialing.store(false, Ordering::SeqCst);
                if attempt == 30 {
                    eprintln!("erro: não conectou a {addr} após tentativas: {e}");
                    return;
                }
                tokio::time::sleep(Duration::from_millis(200)).await;
            }
        }
    }
}

async fn run(cfg: Config) -> Result<(), String> {
    let listener = TcpListener::bind(SocketAddr::from((Ipv4Addr::UNSPECIFIED, cfg.tcp_port)))
        .await
        .map_err(|e| format!("bind TCP :{}: {e}", cfg.tcp_port))?;

    println!("IA_LIVRE_NODE_ID={}", cfg.node_id);
    println!("tcp_port={}", cfg.tcp_port);
    println!("udp_port={}", cfg.udp_port);

    let peer_ok = Arc::new(AtomicBool::new(false));
    let dialing = Arc::new(AtomicBool::new(false));

    let peer_ok_accept = peer_ok.clone();
    tokio::spawn(async move {
        loop {
            match listener.accept().await {
                Ok((stream, addr)) => {
                    if emit_peer_ok(&peer_ok_accept, addr) {
                        run_session(stream).await;
                        break;
                    }
                }
                Err(e) => {
                    eprintln!("aviso: accept TCP: {e}");
                }
            }
        }
    });

    tokio::spawn(run_udp_discovery(
        cfg.node_id.clone(),
        cfg.tcp_port,
        cfg.udp_port,
        peer_ok.clone(),
        dialing.clone(),
    ));

    if let Some(peer) = cfg.peer {
        println!("peer={peer}");
        tokio::spawn(dial_peer(peer, peer_ok.clone(), dialing));
    }

    // Mantém o processo vivo até o gate / operador encerrar.
    loop {
        tokio::time::sleep(Duration::from_secs(3600)).await;
    }
}

#[tokio::main]
async fn main() -> ExitCode {
    let cfg = match parse_args() {
        Ok(c) => c,
        Err(0) => return ExitCode::SUCCESS,
        Err(code) => return ExitCode::from(code as u8),
    };

    if let Err(e) = run(cfg).await {
        eprintln!("erro: {e}");
        return ExitCode::FAILURE;
    }
    ExitCode::SUCCESS
}
