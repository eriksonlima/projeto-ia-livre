//! mDNS real `_ia-livre._tcp` (Etapa 50). Endereço ≠ identidade (IDENT permanece).
//! Crate: `mdns-sd` — sem libp2p.

use std::collections::HashSet;
use std::net::SocketAddr;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

use ed25519_dalek::SigningKey;
use mdns_sd::{ServiceDaemon, ServiceEvent, ServiceInfo};

pub const SERVICE_TYPE: &str = "_ia-livre._tcp.local.";

/// Anuncia o TCP local; se `should_dial`, browse e dial até sessão.
pub async fn run_mdns(
    alias: String,
    tcp_port: u16,
    peer_id: String,
    sk: SigningKey,
    pubkey: String,
    peer_ok: Arc<AtomicBool>,
    dialing: Arc<AtomicBool>,
    should_dial: bool,
) {
    let daemon = match ServiceDaemon::new() {
        Ok(d) => d,
        Err(e) => {
            eprintln!("aviso: mDNS daemon indisponível ({e}); multicast pode estar bloqueado");
            return;
        }
    };

    let instance = format!("{alias}-{tcp_port}");
    let host_name = format!("{instance}.local.");
    let props = [("peer_id", peer_id.as_str())];
    let info = match ServiceInfo::new(
        SERVICE_TYPE,
        &instance,
        &host_name,
        "",
        tcp_port,
        &props[..],
    ) {
        Ok(i) => i.enable_addr_auto(),
        Err(e) => {
            eprintln!("aviso: mDNS ServiceInfo inválido: {e}");
            return;
        }
    };

    if let Err(e) = daemon.register(info) {
        eprintln!("aviso: mDNS register falhou: {e}");
        return;
    }
    println!("IA_LIVRE_DISC_MDNS=announce");
    println!("IA_LIVRE_DISC_MDNS_SVC=_ia-livre._tcp");

    if !should_dial {
        // Só anúncio (dial via peer/bootstrap). Mantém daemon vivo.
        loop {
            tokio::time::sleep(Duration::from_secs(3600)).await;
        }
    }

    println!("IA_LIVRE_DISC_MODE=mdns");
    tokio::time::sleep(Duration::from_millis(500)).await;

    let receiver = match daemon.browse(SERVICE_TYPE) {
        Ok(r) => r,
        Err(e) => {
            eprintln!("aviso: mDNS browse falhou: {e}");
            return;
        }
    };

    let mut tried: HashSet<SocketAddr> = HashSet::new();
    let deadline = tokio::time::Instant::now() + Duration::from_secs(20);

    while tokio::time::Instant::now() < deadline {
        if peer_ok.load(Ordering::SeqCst) {
            println!("IA_LIVRE_DISC_OK");
            return;
        }

        let event = match tokio::task::spawn_blocking({
            let receiver = receiver.clone();
            move || receiver.recv_timeout(Duration::from_millis(400))
        })
        .await
        {
            Ok(Ok(ev)) => ev,
            Ok(Err(_)) => continue,
            Err(_) => continue,
        };

        match event {
            ServiceEvent::ServiceResolved(info) => {
                let full = info.get_fullname().to_string();
                if full.starts_with(&instance) {
                    continue; // self
                }
                let port = info.get_port();
                for addr in info.get_addresses() {
                    let sock = SocketAddr::new(addr.to_ip_addr(), port);
                    if !tried.insert(sock) {
                        continue;
                    }
                    // Evitar dial na própria porta local óbvia
                    if sock.port() == tcp_port && sock.ip().is_loopback() {
                        continue;
                    }
                    println!("IA_LIVRE_DISC_TRY={sock}");
                    let ok = crate::try_dial_addr(
                        sock,
                        sk.clone(),
                        peer_id.clone(),
                        pubkey.clone(),
                        peer_ok.clone(),
                        dialing.clone(),
                    )
                    .await;
                    if ok {
                        println!("IA_LIVRE_DISC_OK");
                        return;
                    }
                }
            }
            ServiceEvent::SearchStarted(_)
            | ServiceEvent::ServiceFound(_, _)
            | ServiceEvent::ServiceRemoved(_, _)
            | ServiceEvent::SearchStopped(_) => {}
            _ => {}
        }
    }

    if peer_ok.load(Ordering::SeqCst) {
        println!("IA_LIVRE_DISC_OK");
    } else {
        eprintln!("aviso: mDNS browse esgotado sem sessão (multicast/timeout)");
    }
}
