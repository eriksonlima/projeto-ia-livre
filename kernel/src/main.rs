#![no_main]
#![no_std]

use core::fmt::Write;
use core::ptr::NonNull;
use uefi::boot::{self, AllocateType, MemoryType, PAGE_SIZE};
use uefi::mem::memory_map::MemoryMap;
use uefi::prelude::*;
use uefi::proto::console::serial::Serial;

const BOOT_OK: &str = "IA_LIVRE_BOOT_OK\n";
const EXIT_BOOT_BEGIN: &str = "IA_LIVRE_EXIT_BOOT_BEGIN\n";

const PROOF_PAGES: usize = 2;
const BUMP_PROOF_BYTES: usize = 64;
/// Iterações do microbenchmark Linha B (proxy pós-ExitBoot).
const NATIVE_BENCH_ITERS: u64 = 200_000;
/// Frequência TSC assumida no QEMU para converter ciclos → ms (documentada).
const TSC_HZ_ASSUMED: u64 = 2_000_000_000;

const COM1: u16 = 0x3F8;

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

fn emit_kv_uefi(sink: &mut LineSink<'_>, key: &str, value: u64) {
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
    sink.emit(core::str::from_utf8(&line[..len]).unwrap());
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

// --- UART COM1 (16550) — único I/O válido após ExitBootServices ---

unsafe fn outb(port: u16, val: u8) {
    core::arch::asm!("out dx, al", in("dx") port, in("al") val, options(nostack, preserves_flags));
}

unsafe fn inb(port: u16) -> u8 {
    let val: u8;
    core::arch::asm!("in al, dx", out("al") val, in("dx") port, options(nostack, preserves_flags));
    val
}

unsafe fn uart_init() {
    outb(COM1 + 1, 0x00); // disable interrupts
    outb(COM1 + 3, 0x80); // DLAB on
    outb(COM1 + 0, 0x01); // divisor lo (115200)
    outb(COM1 + 1, 0x00); // divisor hi
    outb(COM1 + 3, 0x03); // 8N1
    outb(COM1 + 2, 0xC7); // FIFO
    outb(COM1 + 4, 0x0B); // IRQs enabled, RTS/DSR
}

unsafe fn uart_put(b: u8) {
    for _ in 0..100_000 {
        if inb(COM1 + 5) & 0x20 != 0 {
            break;
        }
    }
    outb(COM1, b);
}

unsafe fn uart_write(s: &str) {
    for b in s.bytes() {
        if b == b'\n' {
            uart_put(b'\r');
        }
        uart_put(b);
    }
}

unsafe fn uart_emit_kv(key: &str, value: u64) {
    let mut num = [0u8; 20];
    let digits = format_u64(value, &mut num);
    uart_write(key);
    uart_write(digits);
    uart_write("\n");
}

unsafe fn rdtsc() -> u64 {
    let lo: u32;
    let hi: u32;
    core::arch::asm!(
        "rdtsc",
        out("eax") lo,
        out("edx") hi,
        options(nostack, preserves_flags)
    );
    ((hi as u64) << 32) | (lo as u64)
}

/// Microbenchmark real: toca o bloco LOADER_DATA + trabalho CPU; métricas via RDTSC.
unsafe fn run_native_bench(base: NonNull<u8>, capacity: usize) -> (u64, u64) {
    let slice = core::slice::from_raw_parts_mut(base.as_ptr(), capacity);
    let t0 = rdtsc();
    let mut acc: u64 = 0;
    let mut ops: u64 = 0;
    for i in 0..NATIVE_BENCH_ITERS {
        let idx = (i as usize) % capacity;
        let v = slice[idx].wrapping_add((i as u8).wrapping_mul(17));
        slice[idx] = v;
        acc = acc.wrapping_add(v as u64).wrapping_mul(1315423911);
        ops = ops.wrapping_add(1);
    }
    let t1 = rdtsc();
    let cycles = t1.saturating_sub(t0);
    // Evita otimização total do acc.
    core::hint::black_box(acc);
    let ms = cycles / (TSC_HZ_ASSUMED / 1000);
    (ops, ms)
}

fn halt() -> ! {
    loop {
        unsafe {
            core::arch::asm!("hlt", options(nomem, nostack, preserves_flags));
        }
    }
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

    let map_ok = match boot::memory_map(MemoryType::LOADER_DATA) {
        Ok(map) => {
            let conventional = count_conventional_pages(&map);
            emit_kv_uefi(
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

    let alloc_ptr = match boot::allocate_pages(
        AllocateType::AnyPages,
        MemoryType::LOADER_DATA,
        PROOF_PAGES,
    ) {
        Ok(ptr) => {
            let capacity = PROOF_PAGES * PAGE_SIZE;
            if let Some(used) = prove_bump(ptr, capacity) {
                emit_kv_uefi(&mut sink, "IA_LIVRE_ALLOC_BYTES=", used as u64);
                sink.emit("IA_LIVRE_ALLOC_OK\n");
                Some((ptr, capacity))
            } else {
                None
            }
        }
        Err(_) => None,
    };

    let Some((proof_base, proof_cap)) = alloc_ptr else {
        return Status::SUCCESS;
    };

    sink.emit(EXIT_BOOT_BEGIN);

    // Soltar Serial UEFI antes do exit (protocolos invalidam).
    drop(sink);
    drop(serial);

    // ExitBootServices: mapa owned; Boot Services acabam.
    let map = unsafe { boot::exit_boot_services(MemoryType::LOADER_DATA) };

    unsafe {
        uart_init();

        let pages = count_conventional_pages(&map);
        uart_emit_kv("IA_LIVRE_EXIT_MAP_PAGES=", pages);
        uart_write("IA_LIVRE_EXIT_MAP_OK\n");

        if prove_bump(proof_base, proof_cap).is_some() {
            uart_write("IA_LIVRE_EXIT_MEM_OK\n");
            uart_write("IA_LIVRE_EXIT_BOOT_OK\n");

            // Etapa 12 — proxy Linha B (não é inferência / TinyLlama).
            uart_write("IA_LIVRE_NATIVE_BENCH_BEGIN\n");
            let (ops, ms) = run_native_bench(proof_base, proof_cap);
            uart_emit_kv("IA_LIVRE_NATIVE_BENCH_OPS=", ops);
            uart_emit_kv("IA_LIVRE_NATIVE_BENCH_MS=", ms);
            uart_write("IA_LIVRE_NATIVE_BENCH_OK\n");
        }
    }

    halt()
}
