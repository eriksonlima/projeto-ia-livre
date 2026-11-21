//! CLI do nó Rede IA Livre v1 + descoberta WAN mínima (Etapas 23 / 39 / 50).
//! Identidade ed25519/PeerId, HELLO UDP assinado, IDENT, MSG/ACK, PING/PONG.
//! Bootstrap + mDNS `_ia-livre._tcp` (sem exigir SO IA Livre).

mod discovery;
mod identity;
mod mdns;
mod proto;
mod session;

use std::env;
use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4};
use std::path::PathBuf;
use std::process::ExitCode;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

use ed25519_dalek::SigningKey;
use socket2::{Domain, Protocol, Socket, Type};
use tokio::net::{TcpListener, TcpStream, UdpSocket};
use tokio::time::interval;

use discovery::load_bootstrap;
use identity::{default_key_path, load_or_generate_key, peer_id_from_signing, pubkey_hex};
use proto::{format_hello, parse_hello_v1};
use session::run_session;

const USAGE: &str = "\
Uso: ia-livre-node [--node-id <apelido>] [--tcp-port <porta>] [--udp-port <porta>]
                   [--peer <host:port>] [--bootstrap <host:port>]…
                   [--bootstrap-file <path>] [--disc-mdns] [--key-file <path>]

Nó Rede IA Livre v1 + descoberta (bootstrap / mDNS).
--peer > bootstrap > mdns para dial. Ver docs/rede-descoberta-wan.md.
";

struct Config {
    alias: String,
    tcp_port: u16,
    udp_port: u16,
    peer: Option<String>,
    bootstrap: Vec<String>,
    disc_mdns: bool,
    key_file: PathBuf,
}

fn parse_args() -> Result<Config, i32> {
    let args: Vec<String> = env::args().skip(1).collect();
    let mut alias: Option<String> = None;
    let mut tcp_port: u16 = 7400;
    let mut udp_port: u16 = 7410;
    let mut peer: Option<String> = None;
    let mut bootstrap_cli: Vec<String> = Vec::new();
    let mut bootstrap_file: Option<PathBuf> = None;
    let mut disc_mdns = false;
    let mut key_file: Option<PathBuf> = None;

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
                alias = Some(v.clone());
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
            "--bootstrap" => {
                i += 1;
                let Some(v) = args.get(i) else {
                    eprintln!("erro: --bootstrap exige host:port");
                    return Err(2);
                };
                bootstrap_cli.push(v.clone());
            }
            "--bootstrap-file" => {
                i += 1;
                let Some(v) = args.get(i) else {
                    eprintln!("erro: --bootstrap-file exige um path");
                    return Err(2);
                };
                bootstrap_file = Some(PathBuf::from(v));
            }
            "--disc-mdns" => {
                disc_mdns = true;
            }
            "--key-file" => {
                i += 1;
                let Some(v) = args.get(i) else {
                    eprintln!("erro: --key-file exige um path");
                    return Err(2);
                };
                key_file = Some(PathBuf::from(v));
            }
            other => {
                eprintln!("erro: argumento desconhecido: {other}");
                eprint!("{USAGE}");
                return Err(2);
            }
        }
        i += 1;
    }

    let alias = alias.unwrap_or_else(|| format!("node-{}", std::process::id()));
    let key_file = key_file.unwrap_or_else(|| default_key_path(&alias));
    let bootstrap = match load_bootstrap(&bootstrap_cli, bootstrap_file.as_deref()) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("erro: {e}");
            return Err(2);
        }
    };
    Ok(Config {
        alias,
        tcp_port,
        udp_port,
        peer,
        bootstrap,
        disc_mdns,
        key_file,
    })
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
    sk: SigningKey,
    peer_id: String,
    pubkey: String,
    tcp_port: u16,
    udp_port: u16,
    peer_ok: Arc<AtomicBool>,
    dialing: Arc<AtomicBool>,
) {
    let sock = match bind_udp_reuse(udp_port) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("aviso: UDP descoberta indisponível ({e}); use --peer ou --bootstrap");
            return;
        }
    };

    let hello = format_hello(&sk, &peer_id, tcp_port, &pubkey);
    let targets = [
        SocketAddr::from((Ipv4Addr::LOCALHOST, udp_port)),
        SocketAddr::from((Ipv4Addr::BROADCAST, udp_port)),
    ];

    let mut tick = interval(Duration::from_secs(1));
    let mut buf = [0u8; 2048];

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
                let Some(hello_msg) = parse_hello_v1(line) else { continue };
                if hello_msg.peer_id == peer_id {
                    continue;
                }
                if dialing
                    .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
                    .is_err()
                {
                    continue;
                }
                let dial_addr = SocketAddr::new(src.ip(), hello_msg.tcp_port);
                let peer_ok_c = peer_ok.clone();
                let dialing_c = dialing.clone();
                let sk_c = sk.clone();
                let peer_id_c = peer_id.clone();
                let pubkey_c = pubkey.clone();
                tokio::spawn(async move {
                    match TcpStream::connect(dial_addr).await {
                        Ok(stream) => {
                            run_session(stream, sk_c, peer_id_c, pubkey_c, dial_addr, peer_ok_c).await;
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

pub(crate) async fn try_dial_addr(
    addr: SocketAddr,
    sk: SigningKey,
    peer_id: String,
    pubkey: String,
    peer_ok: Arc<AtomicBool>,
    dialing: Arc<AtomicBool>,
) -> bool {
    for attempt in 1..=30 {
        if peer_ok.load(Ordering::SeqCst) {
            return true;
        }
        if dialing
            .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
            .is_err()
        {
            tokio::time::sleep(Duration::from_millis(200)).await;
            continue;
        }
        match TcpStream::connect(addr).await {
            Ok(stream) => {
                run_session(stream, sk, peer_id, pubkey, addr, peer_ok).await;
                return true;
            }
            Err(e) => {
                dialing.store(false, Ordering::SeqCst);
                if attempt == 30 {
                    eprintln!("aviso: não conectou a {addr} após tentativas: {e}");
                    return false;
                }
                tokio::time::sleep(Duration::from_millis(200)).await;
            }
        }
    }
    false
}

async fn dial_peer(
    peer: String,
    sk: SigningKey,
    peer_id: String,
    pubkey: String,
    peer_ok: Arc<AtomicBool>,
    dialing: Arc<AtomicBool>,
) {
    tokio::time::sleep(Duration::from_millis(300)).await;
    println!("IA_LIVRE_DISC_MODE=peer");
    let addr: SocketAddr = match peer.parse() {
        Ok(a) => a,
        Err(_) => {
            eprintln!("erro: --peer inválido (use host:port): {peer}");
            return;
        }
    };
    if try_dial_addr(addr, sk, peer_id, pubkey, peer_ok, dialing).await {
        println!("IA_LIVRE_DISC_OK");
    }
}

async fn dial_bootstrap(
    endpoints: Vec<String>,
    sk: SigningKey,
    peer_id: String,
    pubkey: String,
    peer_ok: Arc<AtomicBool>,
    dialing: Arc<AtomicBool>,
) {
    tokio::time::sleep(Duration::from_millis(300)).await;
    println!("IA_LIVRE_DISC_MODE=bootstrap");
    for ep in &endpoints {
        if peer_ok.load(Ordering::SeqCst) {
            println!("IA_LIVRE_DISC_OK");
            return;
        }
        let addr: SocketAddr = match ep.parse() {
            Ok(a) => a,
            Err(_) => {
                eprintln!("aviso: bootstrap inválido (use host:port): {ep}");
                continue;
            }
        };
        println!("IA_LIVRE_DISC_TRY={ep}");
        if try_dial_addr(
            addr,
            sk.clone(),
            peer_id.clone(),
            pubkey.clone(),
            peer_ok.clone(),
            dialing.clone(),
        )
        .await
        {
            println!("IA_LIVRE_DISC_OK");
            return;
        }
    }
    eprintln!("erro: bootstrap esgotado sem sessão");
}

async fn run(cfg: Config) -> Result<(), String> {
    let sk = load_or_generate_key(&cfg.key_file)?;
    let peer_id = peer_id_from_signing(&sk);
    let pubkey = pubkey_hex(&sk);

    let listener = TcpListener::bind(SocketAddr::from((Ipv4Addr::UNSPECIFIED, cfg.tcp_port)))
        .await
        .map_err(|e| format!("bind TCP :{}: {e}", cfg.tcp_port))?;

    println!("IA_LIVRE_PROTO=v1");
    println!("IA_LIVRE_NODE_ID={}", cfg.alias);
    println!("IA_LIVRE_PEER_ID={peer_id}");
    println!("tcp_port={}", cfg.tcp_port);
    println!("udp_port={}", cfg.udp_port);
    println!("key_file={}", cfg.key_file.display());

    let peer_ok = Arc::new(AtomicBool::new(false));
    let dialing = Arc::new(AtomicBool::new(false));

    let peer_ok_accept = peer_ok.clone();
    let sk_accept = sk.clone();
    let peer_id_accept = peer_id.clone();
    let pubkey_accept = pubkey.clone();
    tokio::spawn(async move {
        loop {
            match listener.accept().await {
                Ok((stream, addr)) => {
                    if peer_ok_accept.load(Ordering::SeqCst) {
                        continue;
                    }
                    let sk_c = sk_accept.clone();
                    let peer_id_c = peer_id_accept.clone();
                    let pubkey_c = pubkey_accept.clone();
                    let peer_ok_c = peer_ok_accept.clone();
                    tokio::spawn(async move {
                        run_session(stream, sk_c, peer_id_c, pubkey_c, addr, peer_ok_c).await;
                    });
                }
                Err(e) => {
                    eprintln!("aviso: accept TCP: {e}");
                }
            }
        }
    });

    tokio::spawn(run_udp_discovery(
        sk.clone(),
        peer_id.clone(),
        pubkey.clone(),
        cfg.tcp_port,
        cfg.udp_port,
        peer_ok.clone(),
        dialing.clone(),
    ));

    // mDNS: anuncia sempre com --disc-mdns; dial só se não houver peer/bootstrap.
    let mdns_should_dial = cfg.disc_mdns && cfg.peer.is_none() && cfg.bootstrap.is_empty();
    if cfg.disc_mdns {
        tokio::spawn(mdns::run_mdns(
            cfg.alias.clone(),
            cfg.tcp_port,
            peer_id.clone(),
            sk.clone(),
            pubkey.clone(),
            peer_ok.clone(),
            dialing.clone(),
            mdns_should_dial,
        ));
    }

    // Precedência dial: --peer > bootstrap > mdns > LAN-only.
    if let Some(peer) = cfg.peer {
        println!("peer={peer}");
        tokio::spawn(dial_peer(
            peer,
            sk,
            peer_id,
            pubkey,
            peer_ok.clone(),
            dialing,
        ));
    } else if !cfg.bootstrap.is_empty() {
        println!("bootstrap={}", cfg.bootstrap.join(","));
        tokio::spawn(dial_bootstrap(
            cfg.bootstrap,
            sk,
            peer_id,
            pubkey,
            peer_ok.clone(),
            dialing,
        ));
    }

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
