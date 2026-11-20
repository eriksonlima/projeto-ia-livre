#![no_main]
#![no_std]

use uefi::prelude::*;

/// Entry UEFI do kernel IA Livre (scaffold — Task 1).
/// A mensagem serial canônica `IA_LIVRE_BOOT_OK` entra na Task 2.
#[entry]
fn main() -> Status {
    uefi::helpers::init().unwrap();
    // Placeholder estável até a Task 2 (hello serial verificável).
    uefi::println!("IA Livre kernel scaffold");
    Status::SUCCESS
}
