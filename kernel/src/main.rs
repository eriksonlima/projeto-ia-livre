#![no_main]
#![no_std]

use core::fmt::Write;
use uefi::prelude::*;
use uefi::proto::console::serial::Serial;
use uefi::boot;

/// Mensagem canônica do gate (Etapa 4 / Task 2). Não alterar sem atualizar AGENTS.md.
const BOOT_OK: &str = "IA_LIVRE_BOOT_OK\n";

#[entry]
fn main() -> Status {
    uefi::helpers::init().unwrap();

    // Serial I/O UEFI → QEMU `-serial stdio`
    if let Ok(handle) = boot::get_handle_for_protocol::<Serial>() {
        if let Ok(mut serial) = boot::open_protocol_exclusive::<Serial>(handle) {
            let _ = serial.write_str(BOOT_OK);
        }
    }

    // Também no console UEFI (muitas configs QEMU redirecionam ConOut à serial)
    uefi::print!("{BOOT_OK}");

    Status::SUCCESS
}
