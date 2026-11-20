#![no_main]
#![no_std]

use core::fmt::Write;
use core::ptr::NonNull;
use uefi::boot::{self, AllocateType, MemoryType, PAGE_SIZE};
use uefi::mem::memory_map::MemoryMap;
use uefi::prelude::*;
use uefi::proto::console::serial::Serial;

/// Mensagem canônica do gate (Etapa 4). Não alterar o texto sem atualizar AGENTS.md.
const BOOT_OK: &str = "IA_LIVRE_BOOT_OK\n";

/// Páginas de 4 KiB alocadas para a prova do bump (Etapa 10).
const PROOF_PAGES: usize = 2;
/// Bytes pedidos ao bump dentro do bloco (prova write/read).
const BUMP_PROOF_BYTES: usize = 64;

struct LineSink<'a> {
    serial: Option<&'a mut Serial>,
}

impl LineSink<'_> {
    fn emit(&mut self, line: &str) {
        if let Some(serial) = self.serial.as_mut() {
            let _ = serial.write_str(line);
        }
        uefi::print!("{line}");
    }
}

struct Bump {
    base: NonNull<u8>,
    capacity: usize,
    offset: usize,
}

impl Bump {
    fn new(base: NonNull<u8>, capacity: usize) -> Self {
        Self {
            base,
            capacity,
            offset: 0,
        }
    }

    fn alloc(&mut self, size: usize) -> Option<NonNull<u8>> {
        let aligned = (self.offset + 7) & !7;
        let end = aligned.checked_add(size)?;
        if end > self.capacity {
            return None;
        }
        let ptr = unsafe { NonNull::new_unchecked(self.base.as_ptr().add(aligned)) };
        self.offset = end;
        Some(ptr)
    }
}

fn format_u64(mut n: u64, buf: &mut [u8; 20]) -> &str {
    if n == 0 {
        buf[19] = b'0';
        return core::str::from_utf8(&buf[19..]).unwrap();
    }
    let mut i = 20;
    while n > 0 {
        i -= 1;
        buf[i] = b'0' + (n % 10) as u8;
        n /= 10;
    }
    core::str::from_utf8(&buf[i..]).unwrap()
}

fn emit_kv(sink: &mut LineSink<'_>, key: &str, value: u64) {
    let mut num = [0u8; 20];
    let digits = format_u64(value, &mut num);
    let mut line = [0u8; 96];
    let mut len = 0usize;
    for b in key.bytes() {
        line[len] = b;
        len += 1;
    }
    for b in digits.bytes() {
        line[len] = b;
        len += 1;
    }
    line[len] = b'\n';
    len += 1;
    let s = core::str::from_utf8(&line[..len]).unwrap();
    sink.emit(s);
}

fn count_conventional_pages(map: &impl MemoryMap) -> u64 {
    let mut pages = 0u64;
    for desc in map.entries() {
        if desc.ty == MemoryType::CONVENTIONAL {
            pages = pages.saturating_add(desc.page_count);
        }
    }
    pages
}

fn prove_bump(base: NonNull<u8>, capacity: usize) -> Option<usize> {
    let mut bump = Bump::new(base, capacity);
    let chunk = bump.alloc(BUMP_PROOF_BYTES)?;
    let slice = unsafe { core::slice::from_raw_parts_mut(chunk.as_ptr(), BUMP_PROOF_BYTES) };
    for (i, b) in slice.iter_mut().enumerate() {
        *b = (i as u8).wrapping_mul(3).wrapping_add(0xA5);
    }
    for (i, b) in slice.iter().enumerate() {
        let expected = (i as u8).wrapping_mul(3).wrapping_add(0xA5);
        if *b != expected {
            return None;
        }
    }
    Some(BUMP_PROOF_BYTES)
}

#[entry]
fn main() -> Status {
    uefi::helpers::init().unwrap();

    let serial_handle = boot::get_handle_for_protocol::<Serial>().ok();
    let mut serial = serial_handle.and_then(|h| boot::open_protocol_exclusive::<Serial>(h).ok());
    let mut sink = LineSink {
        serial: serial.as_mut().map(|s| &mut **s),
    };

    sink.emit(BOOT_OK);

    // --- Mapa de memória UEFI (Boot Services) ---
    let map_ok = match boot::memory_map(MemoryType::LOADER_DATA) {
        Ok(map) => {
            let conventional = count_conventional_pages(&map);
            emit_kv(
                &mut sink,
                "IA_LIVRE_MEM_CONVENTIONAL_PAGES=",
                conventional,
            );
            sink.emit("IA_LIVRE_MEM_MAP_OK\n");
            true
        }
        Err(_) => false,
    };

    if !map_ok {
        return Status::SUCCESS;
    }

    // --- AllocatePages + bump ---
    match boot::allocate_pages(
        AllocateType::AnyPages,
        MemoryType::LOADER_DATA,
        PROOF_PAGES,
    ) {
        Ok(ptr) => {
            let capacity = PROOF_PAGES * PAGE_SIZE;
            if let Some(used) = prove_bump(ptr, capacity) {
                emit_kv(&mut sink, "IA_LIVRE_ALLOC_BYTES=", used as u64);
                sink.emit("IA_LIVRE_ALLOC_OK\n");
            }
            // Bloco permanece alocado até o fim do app UEFI (sem ExitBoot).
            let _ = ptr;
        }
        Err(_) => {}
    }

    Status::SUCCESS
}
