#![no_main]
#![no_std]

use core::fmt::Write;
use core::ptr::NonNull;
use uefi::boot::{
    self, AllocateType, MemoryType, OpenProtocolAttributes, OpenProtocolParams, SearchType,
    PAGE_SIZE,
};
use uefi::cstr16;
use uefi::mem::memory_map::MemoryMap;
use uefi::prelude::*;
use uefi::proto::console::serial::Serial;
use uefi::proto::media::block::BlockIO;
use uefi::proto::media::file::{File, FileAttribute, FileMode};

const BOOT_OK: &str = "IA_LIVRE_BOOT_OK\n";
const EXIT_BOOT_BEGIN: &str = "IA_LIVRE_EXIT_BOOT_BEGIN\n";

const PROOF_PAGES: usize = 2;
const BUMP_PROOF_BYTES: usize = 64;
/// Iterações do microbenchmark Linha B (proxy pós-ExitBoot).
const NATIVE_BENCH_ITERS: u64 = 200_000;
/// Frequência TSC assumida no QEMU para converter ciclos → ms (documentada).
const TSC_HZ_ASSUMED: u64 = 2_000_000_000;

/// Etapa 19 — tamanhos fixos do allocator tipado (docs/memoria-scheduler-impl-minima.md).
const TYPED_WEIGHTS_BYTES: usize = 128;
const TYPED_KVCACHE_BYTES: usize = 256;
/// Política de quantum mínima (Prefill > Decode); unidades arbitrárias.
const QUANTUM_PREFILL: u64 = 8;
const QUANTUM_DECODE: u64 = 2;

/// Etapa 26 — prefixo GGUF no ESP; Etapa 27 — arquivo completo quando presente (ADR 0008/0009).
const GGUF_PREFIX_MAX: usize = 4096;
const GGUF_MAGIC: [u8; 4] = *b"GGUF";

#[derive(Clone, Copy, PartialEq, Eq)]
enum MemClass {
    Weights,
    KvCache,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum Phase {
    Prefill,
    Decode,
}

impl Phase {
    fn marker(self) -> &'static str {
        match self {
            Phase::Prefill => "IA_LIVRE_PHASE=prefill\n",
            Phase::Decode => "IA_LIVRE_PHASE=decode\n",
        }
    }

    fn quantum(self) -> u64 {
        match self {
            Phase::Prefill => QUANTUM_PREFILL,
            Phase::Decode => QUANTUM_DECODE,
        }
    }
}

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

fn typed_alloc(bump: &mut Bump, class: MemClass, size: usize) -> Option<(MemClass, NonNull<u8>, usize)> {
    let ptr = bump.alloc(size)?;
    Some((class, ptr, size))
}

fn prove_typed_region(ptr: NonNull<u8>, size: usize, salt: u8) -> bool {
    let slice = unsafe { core::slice::from_raw_parts_mut(ptr.as_ptr(), size) };
    for (i, b) in slice.iter_mut().enumerate() {
        *b = (i as u8).wrapping_mul(5).wrapping_add(salt);
    }
    for (i, b) in slice.iter().enumerate() {
        let expected = (i as u8).wrapping_mul(5).wrapping_add(salt);
        if *b != expected {
            return false;
        }
    }
    true
}

fn parse_ascii_u64(buf: &[u8]) -> Option<u64> {
    let mut n = 0u64;
    let mut any = false;
    for &b in buf {
        if b == b'\n' || b == b'\r' || b == 0 {
            break;
        }
        if b.is_ascii_whitespace() {
            continue;
        }
        if !(b'0'..=b'9').contains(&b) {
            return None;
        }
        any = true;
        n = n.saturating_mul(10).saturating_add((b - b'0') as u64);
    }
    if any {
        Some(n)
    } else {
        None
    }
}

fn read_u64_le(buf: &[u8]) -> Option<u64> {
    if buf.len() < 8 {
        return None;
    }
    let mut a = [0u8; 8];
    a.copy_from_slice(&buf[..8]);
    Some(u64::from_le_bytes(a))
}

/// Carrega GGUF completo de um BlockIO cujo tamanho ≈ `want` (disco raw QEMU).
fn try_load_gguf_blockio(sink: &mut LineSink<'_>, want: u64) -> Option<(NonNull<u8>, usize)> {
    if want < 16 {
        return None;
    }
    let handles = boot::locate_handle_buffer(SearchType::from_proto::<BlockIO>()).ok()?;
    for &handle in handles.iter() {
        let bio = unsafe {
            boot::open_protocol::<BlockIO>(
                OpenProtocolParams {
                    handle,
                    agent: boot::image_handle(),
                    controller: None,
                },
                OpenProtocolAttributes::GetProtocol,
            )
        };
        let Ok(bio) = bio else {
            continue;
        };
        let media = bio.media();
        if !media.is_media_present() {
            continue;
        }
        let bs = media.block_size() as u64;
        if bs == 0 {
            continue;
        }
        let media_bytes = media.last_block().saturating_add(1).saturating_mul(bs);
        // Aceita mídia com tamanho == want (arquivo raw) ou want arredondado a bloco.
        if media_bytes < want || media_bytes > want.saturating_add(bs) {
            continue;
        }
        let read_len = ((want as usize + bs as usize - 1) / bs as usize) * bs as usize;
        let pages = (read_len + PAGE_SIZE - 1) / PAGE_SIZE;
        let base = boot::allocate_pages(AllocateType::AnyPages, MemoryType::LOADER_DATA, pages).ok()?;
        let buf = unsafe { core::slice::from_raw_parts_mut(base.as_ptr(), read_len) };
        // Alinhamento: buffer em páginas deve satisfazer io_align típico.
        if bio
            .read_blocks(media.media_id(), 0, buf)
            .is_err()
        {
            continue;
        }
        let n = want as usize;
        if n < 16 || buf[..4] != GGUF_MAGIC {
            continue;
        }
        sink.emit("IA_LIVRE_GGUF_MAGIC_OK\n");
        emit_kv_uefi(sink, "IA_LIVRE_GGUF_FILE_BYTES=", want);
        emit_kv_uefi(sink, "IA_LIVRE_GGUF_BYTES=", n as u64);
        sink.emit("IA_LIVRE_GGUF_HEADER_OK\n");
        sink.emit("IA_LIVRE_GGUF_NATIVE_LOADER=blockio_full\n");
        if let Some(tc) = read_u64_le(&buf[8..]) {
            emit_kv_uefi(sink, "IA_LIVRE_GGUF_TENSOR_COUNT=", tc);
            sink.emit("IA_LIVRE_GGUF_TENSORS_STUB_OK\n");
            sink.emit("IA_LIVRE_GGUF_STATUS=tensors_stub_ok\n");
        }
        return Some((base, n));
    }
    None
}

/// Etapa 26/27: lê GGUF do ESP (completo se `model.gguf` + size; senão prefixo `gguf.hdr`).
fn try_load_gguf(sink: &mut LineSink<'_>) -> Option<(NonNull<u8>, usize)> {
    sink.emit("IA_LIVRE_GGUF_LOADER_BEGIN\n");

    let mut sfs = match boot::get_image_file_system(boot::image_handle()) {
        Ok(fs) => fs,
        Err(_) => {
            sink.emit("IA_LIVRE_GGUF_LOADER_FAIL=no_fs\n");
            return None;
        }
    };
    let mut root = match sfs.open_volume() {
        Ok(d) => d,
        Err(_) => {
            sink.emit("IA_LIVRE_GGUF_LOADER_FAIL=open_volume\n");
            return None;
        }
    };

    // Etapa 27: tamanho esperado no ESP; bytes via BlockIO (disco raw QEMU).
    // Motivo: fat:rw do QEMU é FAT16 (~516 MiB) — GGUF ~638 MiB não cabe no ESP.
    let want_sz = (|| {
        let mut sz_file = root
            .open(
                cstr16!("\\IA_LIVRE\\model.gguf.sz"),
                FileMode::Read,
                FileAttribute::empty(),
            )
            .ok()?
            .into_regular_file()?;
        let mut sz_buf = [0u8; 32];
        let sn = sz_file.read(&mut sz_buf).ok()?;
        parse_ascii_u64(&sz_buf[..sn])
    })();

    if let Some(want) = want_sz {
        if let Some((base, n)) = try_load_gguf_blockio(sink, want) {
            return Some((base, n));
        }
        sink.emit("IA_LIVRE_GGUF_LOADER_FAIL=blockio\n");
    }

    // Fallback Etapa 26: só prefixo.
    let handle = match root.open(
        cstr16!("\\IA_LIVRE\\gguf.hdr"),
        FileMode::Read,
        FileAttribute::empty(),
    ) {
        Ok(h) => h,
        Err(_) => {
            sink.emit("IA_LIVRE_GGUF_LOADER_FAIL=open_file\n");
            return None;
        }
    };
    let mut file = match handle.into_regular_file() {
        Some(f) => f,
        None => {
            sink.emit("IA_LIVRE_GGUF_LOADER_FAIL=not_file\n");
            return None;
        }
    };

    let pages = (GGUF_PREFIX_MAX + PAGE_SIZE - 1) / PAGE_SIZE;
    let base = match boot::allocate_pages(AllocateType::AnyPages, MemoryType::LOADER_DATA, pages) {
        Ok(p) => p,
        Err(_) => {
            sink.emit("IA_LIVRE_GGUF_LOADER_FAIL=alloc\n");
            return None;
        }
    };
    let buf = unsafe { core::slice::from_raw_parts_mut(base.as_ptr(), GGUF_PREFIX_MAX) };
    let n = match file.read(buf) {
        Ok(n) => n,
        Err(_) => {
            sink.emit("IA_LIVRE_GGUF_LOADER_FAIL=read\n");
            return None;
        }
    };
    if n < 4 || buf[..4] != GGUF_MAGIC {
        sink.emit("IA_LIVRE_GGUF_LOADER_FAIL=magic\n");
        return None;
    }

    sink.emit("IA_LIVRE_GGUF_MAGIC_OK\n");
    emit_kv_uefi(sink, "IA_LIVRE_GGUF_BYTES=", n as u64);
    sink.emit("IA_LIVRE_GGUF_HEADER_OK\n");
    sink.emit("IA_LIVRE_GGUF_NATIVE_LOADER=esp_header\n");
    Some((base, n))
}

/// Demo Etapa 19: allocator tipado + Prefill/Decode + quantum. Emite MEM_SCHED_OK só se ok.
/// Se `gguf` presente, copia min(Weights, bytes) do prefixo para a região Weights (seed).
unsafe fn run_mem_sched_demo(
    base: NonNull<u8>,
    capacity: usize,
    gguf: Option<(NonNull<u8>, usize)>,
) -> bool {
    let mut bump = Bump::new(base, capacity);

    let Some((_c, w_ptr, w_sz)) = typed_alloc(&mut bump, MemClass::Weights, TYPED_WEIGHTS_BYTES) else {
        return false;
    };
    if let Some((g_ptr, g_n)) = gguf {
        let src = core::slice::from_raw_parts(g_ptr.as_ptr(), g_n);
        let dst = core::slice::from_raw_parts_mut(w_ptr.as_ptr(), w_sz);
        let n = core::cmp::min(dst.len(), src.len());
        dst[..n].copy_from_slice(&src[..n]);
        uart_write("IA_LIVRE_GGUF_WEIGHTS_SEEDED\n");
    } else if !prove_typed_region(w_ptr, w_sz, 0x11) {
        return false;
    }
    uart_emit_kv("IA_LIVRE_TYPED_WEIGHTS_BYTES=", w_sz as u64);
    uart_write("IA_LIVRE_TYPED_WEIGHTS_OK\n");

    let Some((_c, k_ptr, k_sz)) = typed_alloc(&mut bump, MemClass::KvCache, TYPED_KVCACHE_BYTES) else {
        return false;
    };
    if !prove_typed_region(k_ptr, k_sz, 0x22) {
        return false;
    }
    uart_emit_kv("IA_LIVRE_TYPED_KVCACHE_BYTES=", k_sz as u64);
    uart_write("IA_LIVRE_TYPED_KVCACHE_OK\n");

    if QUANTUM_PREFILL <= QUANTUM_DECODE {
        return false;
    }

    let mut phase = Phase::Prefill;
    uart_write(phase.marker());
    uart_emit_kv("IA_LIVRE_QUANTUM=", phase.quantum());

    phase = Phase::Decode;
    uart_write(phase.marker());
    uart_emit_kv("IA_LIVRE_QUANTUM=", phase.quantum());

    uart_write("IA_LIVRE_MEM_SCHED_OK\n");
    true
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

    // Etapa 26 — loader GGUF mínimo (ESP) sob Boot Services; sem TOKENS_PER_S.
    let gguf_prefix = try_load_gguf(&mut sink);

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

            // Reemite evidência do loader na UART COM1 (harness pós-exit).
            if let Some((p, n)) = gguf_prefix {
                uart_write("IA_LIVRE_GGUF_MAGIC_OK\n");
                uart_emit_kv("IA_LIVRE_GGUF_BYTES=", n as u64);
                uart_write("IA_LIVRE_GGUF_HEADER_OK\n");
                if n > GGUF_PREFIX_MAX {
                    uart_write("IA_LIVRE_GGUF_NATIVE_LOADER=blockio_full\n");
                    let slice = core::slice::from_raw_parts(p.as_ptr(), n);
                    if let Some(tc) = read_u64_le(&slice[8..]) {
                        uart_emit_kv("IA_LIVRE_GGUF_TENSOR_COUNT=", tc);
                        uart_write("IA_LIVRE_GGUF_TENSORS_STUB_OK\n");
                        uart_write("IA_LIVRE_GGUF_STATUS=tensors_stub_ok\n");
                    }
                } else {
                    uart_write("IA_LIVRE_GGUF_NATIVE_LOADER=esp_header\n");
                }
            }

            // Etapa 19 — memória tipada + Prefill/Decode (≠ NATIVE_BENCH / ≠ geração GGUF).
            let _ = run_mem_sched_demo(proof_base, proof_cap, gguf_prefix);

            // Etapa 29/31/32 — runtime-native: layout + mapa/dequant/op + tokenize/embed/camada.
            uart_write("IA_LIVRE_NATIVE_INFER_BEGIN\n");
            if let Some((p, n)) = gguf_prefix {
                if n > GGUF_PREFIX_MAX {
                    let slice = core::slice::from_raw_parts(p.as_ptr(), n);
                    match ia_livre_runtime_native::prepare(slice) {
                        Ok(layout) => {
                            uart_emit_kv(
                                "IA_LIVRE_GGUF_TENSOR_COUNT=",
                                layout.tensor_count,
                            );
                            uart_emit_kv(
                                "IA_LIVRE_RUNTIME_NATIVE_TENSORS_PARSED=",
                                layout.tensors_parsed,
                            );
                            uart_emit_kv(
                                "IA_LIVRE_RUNTIME_NATIVE_DATA_OFF=",
                                layout.data_offset as u64,
                            );
                            uart_write("IA_LIVRE_RUNTIME_NATIVE_LAYOUT_OK\n");
                            uart_write("IA_LIVRE_GGUF_STATUS=layout_ok\n");
                            match ia_livre_runtime_native::try_forward_partial(slice, &layout) {
                                Ok(partial) => {
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_TENSOR_MAP_OK\n");
                                    uart_emit_kv(
                                        "IA_LIVRE_RUNTIME_NATIVE_DEQUANT_CS=",
                                        partial.dequant_checksum_milli as u64,
                                    );
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_Q4K_DEQUANT_OK\n");
                                    uart_emit_kv(
                                        "IA_LIVRE_RUNTIME_NATIVE_OP_CS=",
                                        partial.op_checksum_milli as u64,
                                    );
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_FORWARD_OP_OK\n");
                                }
                                Err(_) => {
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_PARTIAL_FAIL\n");
                                }
                            }
                            let tok = ia_livre_runtime_native::tokenize_canonical();
                            uart_emit_kv(
                                "IA_LIVRE_RUNTIME_NATIVE_TOKEN_N=",
                                tok.n_tokens as u64,
                            );
                            uart_write("IA_LIVRE_RUNTIME_NATIVE_TOKENIZE_OK\n");
                            match ia_livre_runtime_native::try_layer_partial_canonical(
                                slice, &layout,
                            ) {
                                Ok(layer) => {
                                    uart_emit_kv(
                                        "IA_LIVRE_RUNTIME_NATIVE_EMBED_CS=",
                                        layer.embed_checksum_milli as u64,
                                    );
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_EMBED_OK\n");
                                    uart_emit_kv(
                                        "IA_LIVRE_RUNTIME_NATIVE_LAYER_CS=",
                                        layer.layer_checksum_milli as u64,
                                    );
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_LAYER_PARTIAL_OK\n");
                                }
                                Err(_) => {
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_LAYER_FAIL\n");
                                }
                            }
                            match ia_livre_runtime_native::try_attn_layer0_single(slice, &layout)
                            {
                                Ok(attn) => {
                                    uart_emit_kv(
                                        "IA_LIVRE_RUNTIME_NATIVE_ATTN_CS=",
                                        attn.attn_checksum_milli as u64,
                                    );
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_ATTN_LAYER_OK\n");
                                }
                                Err(_) => {
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_ATTN_LAYER_FAIL\n");
                                }
                            }
                            match ia_livre_runtime_native::try_prefill_layer0(slice, &layout) {
                                Ok(pre) => {
                                    uart_emit_kv(
                                        "IA_LIVRE_RUNTIME_NATIVE_FFN_CS=",
                                        pre.ffn.ffn_checksum_milli as u64,
                                    );
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_FFN_LAYER_OK\n");
                                    uart_emit_kv(
                                        "IA_LIVRE_RUNTIME_NATIVE_PREFILL_LAYERS=",
                                        pre.n_layers as u64,
                                    );
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_PREFILL_OK\n");
                                }
                                Err(_) => {
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_PREFILL_FAIL\n");
                                }
                            }
                            match ia_livre_runtime_native::try_forward_canonical(slice, &layout)
                            {
                                Ok(()) => {
                                    uart_write("IA_LIVRE_RUNTIME_NATIVE_OK\n");
                                }
                                Err(ia_livre_runtime_native::ForwardError::NoFullPrefill) => {
                                    uart_write(
                                        "IA_LIVRE_RUNTIME_NATIVE_FORWARD_FAIL=no_full_prefill\n",
                                    );
                                }
                                Err(ia_livre_runtime_native::ForwardError::NoDecode) => {
                                    uart_write(
                                        "IA_LIVRE_RUNTIME_NATIVE_FORWARD_FAIL=no_decode\n",
                                    );
                                }
                                Err(ia_livre_runtime_native::ForwardError::NoGenerate) => {
                                    uart_write(
                                        "IA_LIVRE_RUNTIME_NATIVE_FORWARD_FAIL=no_generate\n",
                                    );
                                }
                                Err(_) => {
                                    uart_write(
                                        "IA_LIVRE_RUNTIME_NATIVE_FORWARD_FAIL=other\n",
                                    );
                                }
                            }
                        }
                        Err(_) => {
                            uart_write("IA_LIVRE_RUNTIME_NATIVE_LAYOUT_FAIL\n");
                            uart_write("IA_LIVRE_GGUF_STATUS=tensors_stub_ok\n");
                        }
                    }
                } else {
                    uart_write("IA_LIVRE_RUNTIME_NATIVE_SKIP=esp_header_only\n");
                }
            } else {
                uart_write("IA_LIVRE_RUNTIME_NATIVE_SKIP=no_gguf\n");
            }

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
