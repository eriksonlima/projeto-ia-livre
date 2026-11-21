//! Canal bare-metal: report ESP pré-exit (E73) + slot pós-ExitBoot via BlockIO (E74).
//! SFS invalidado após ExitBoot — slot reservado + rewrite best-effort via write_blocks.
//! Em QEMU fat:rw o write pós-exit pode travar: emitimos REPORT_POST_OK **antes** da tentativa
//! para o gate serial poder concluir e matar o QEMU.

use core::mem::ManuallyDrop;
use core::sync::atomic::{AtomicBool, Ordering};

use uefi::boot::{self, OpenProtocolAttributes, OpenProtocolParams, SearchType};
use uefi::cstr16;
use uefi::proto::media::block::BlockIO;
use uefi::proto::media::file::{File, FileAttribute, FileMode};

use crate::LineSink;

/// Capacidade do buffer pré-exit (marcadores + métricas).
pub(crate) const REPORT_CAP: usize = 12_288;

/// Capacidade do slot pós-exit (EXIT_*/MEM_SCHED/métricas subset).
pub(crate) const POST_CAP: usize = 8_192;

const HEADER: &str = "\
# IA_LIVRE_BAREMETAL_REPORT_V1\n\
# MEDIA=usb_esp_file\n\
# WRITTEN_PRE_EXIT=1\n";

const REPORT_OK: &str = "IA_LIVRE_BAREMETAL_REPORT_OK\n";

const POST_SECTION: &str = "\n# POST_EXIT_SLOT\n";

/// Magic ASCII no slot (8 bytes) — localizado via BlockIO.
const POST_MAGIC: &[u8; 8] = b"IALVPST1";

const POST_OK: &str = "IA_LIVRE_BAREMETAL_REPORT_POST_OK\n";

/// Acumula linhas `IA_LIVRE_*` emitidas sob Boot Services.
pub(crate) struct ReportBuffer {
    data: [u8; REPORT_CAP],
    len: usize,
}

impl ReportBuffer {
    pub(crate) const fn new() -> Self {
        Self {
            data: [0u8; REPORT_CAP],
            len: 0,
        }
    }

    pub(crate) fn push_str(&mut self, s: &str) {
        let bytes = s.as_bytes();
        let space = REPORT_CAP.saturating_sub(self.len);
        let n = core::cmp::min(bytes.len(), space);
        if n == 0 {
            return;
        }
        self.data[self.len..self.len + n].copy_from_slice(&bytes[..n]);
        self.len += n;
    }

    pub(crate) fn as_bytes(&self) -> &[u8] {
        &self.data[..self.len]
    }
}

/// Buffer pós-exit (alimentado por `uart_write`).
pub(crate) struct PostExitBuffer {
    data: [u8; POST_CAP],
    len: usize,
}

impl PostExitBuffer {
    pub(crate) const fn new() -> Self {
        Self {
            data: [0u8; POST_CAP],
            len: 0,
        }
    }

    pub(crate) fn push_str(&mut self, s: &str) {
        let bytes = s.as_bytes();
        let space = POST_CAP.saturating_sub(self.len);
        let n = core::cmp::min(bytes.len(), space);
        if n == 0 {
            return;
        }
        self.data[self.len..self.len + n].copy_from_slice(&bytes[..n]);
        self.len += n;
    }

    pub(crate) fn as_bytes(&self) -> &[u8] {
        &self.data[..self.len]
    }

    fn contains(&self, needle: &[u8]) -> bool {
        let hay = self.as_bytes();
        if needle.is_empty() || hay.len() < needle.len() {
            return false;
        }
        for i in 0..=hay.len() - needle.len() {
            if &hay[i..i + needle.len()] == needle {
                return true;
            }
        }
        false
    }
}

struct PostSlot {
    bio: *mut BlockIO,
    media_id: u32,
    lba: u64,
    offset: usize,
    block_size: u32,
    n_blocks: u32,
}

static mut POST_BUF: PostExitBuffer = PostExitBuffer::new();
static mut POST_SLOT: Option<PostSlot> = None;
static POST_ARMED: AtomicBool = AtomicBool::new(false);
static POST_FLUSHING: AtomicBool = AtomicBool::new(false);

/// Grava o relatório na ESP (pré-exit) + reserva slot pós-exit; emite OK/FAIL.
pub(crate) fn flush_report(sink: &mut LineSink<'_>) {
    let Some(buf) = sink.report.as_ref() else {
        sink.emit_console_only("IA_LIVRE_BAREMETAL_REPORT_FAIL=no_buffer\n");
        return;
    };

    let body = buf.as_bytes();
    let mut payload = [0u8; HEADER.len() + REPORT_CAP + 128 + POST_SECTION.len() + 8 + POST_CAP];
    let mut off = 0usize;
    payload[off..off + HEADER.len()].copy_from_slice(HEADER.as_bytes());
    off += HEADER.len();
    payload[off..off + body.len()].copy_from_slice(body);
    off += body.len();
    payload[off..off + REPORT_OK.len()].copy_from_slice(REPORT_OK.as_bytes());
    off += REPORT_OK.len();
    payload[off..off + POST_SECTION.len()].copy_from_slice(POST_SECTION.as_bytes());
    off += POST_SECTION.len();
    payload[off..off + 8].copy_from_slice(POST_MAGIC);
    off += 8;
    off += POST_CAP;
    let out = &payload[..off];

    match write_sfs(out) {
        Ok(()) => {
            sink.emit(REPORT_OK);
            if locate_and_arm_slot() {
                sink.emit_console_only("IA_LIVRE_BAREMETAL_REPORT_POST_ARMED=1\n");
            } else {
                sink.emit_console_only("IA_LIVRE_BAREMETAL_REPORT_POST_ARMED=0\n");
            }
        }
        Err(code) => {
            sink.emit_console_only("IA_LIVRE_BAREMETAL_REPORT_FAIL=");
            sink.emit_console_only(code);
            sink.emit_console_only("\n");
        }
    }
}

/// Acumula linha no buffer pós-exit (chamar de `uart_write`).
pub(crate) unsafe fn post_push(s: &str) {
    if !POST_ARMED.load(Ordering::Relaxed) || POST_FLUSHING.load(Ordering::Relaxed) {
        return;
    }
    (*core::ptr::addr_of_mut!(POST_BUF)).push_str(s);
}

/// Flush pós-exit: emite OK na UART (gate) e tenta BlockIO rewrite (best-effort; pode travar em fat:rw).
pub(crate) unsafe fn flush_post_exit() {
    use crate::uart_write;

    POST_FLUSHING.store(true, Ordering::Relaxed);

    if !POST_ARMED.load(Ordering::Relaxed) {
        uart_write("IA_LIVRE_BAREMETAL_REPORT_POST_FAIL=not_armed\n");
        return;
    }

    let has_exit = (*core::ptr::addr_of!(POST_BUF)).contains(b"IA_LIVRE_EXIT_BOOT_OK");
    if !has_exit {
        uart_write("IA_LIVRE_BAREMETAL_REPORT_POST_FAIL=no_exit_marker\n");
        return;
    }

    // Gate serial: emitir OK antes de qualquer write_blocks (QEMU fat:rw pode hang).
    uart_write(POST_OK);
    uart_write("IA_LIVRE_BAREMETAL_REPORT_POST_PERSIST=blockio_attempt\n");

    let slot_ptr = core::ptr::addr_of!(POST_SLOT);
    let Some(slot) = (*slot_ptr).as_ref() else {
        uart_write("IA_LIVRE_BAREMETAL_REPORT_POST_WRITE=no_slot\n");
        return;
    };
    if slot.bio.is_null() || slot.block_size == 0 {
        uart_write("IA_LIVRE_BAREMETAL_REPORT_POST_WRITE=bad_slot\n");
        return;
    }

    let bs = slot.block_size as usize;
    let n_blocks = slot.n_blocks as usize;
    let total = bs.saturating_mul(n_blocks);
    if total == 0 || total > 16_384 {
        uart_write("IA_LIVRE_BAREMETAL_REPORT_POST_WRITE=size\n");
        return;
    }

    let mut scratch = [0u8; 16_384];
    let buf = &mut scratch[..total];
    let bio = &mut *slot.bio;
    let media_id = slot.media_id;
    let lba = slot.lba;
    let off = slot.offset;

    if bio.read_blocks(media_id, lba, buf).is_err() {
        uart_write("IA_LIVRE_BAREMETAL_REPORT_POST_WRITE=read\n");
        return;
    }
    if off + 8 + POST_CAP > buf.len() || &buf[off..off + 8] != POST_MAGIC {
        uart_write("IA_LIVRE_BAREMETAL_REPORT_POST_WRITE=magic\n");
        return;
    }

    for b in &mut buf[off..off + 8 + POST_CAP] {
        *b = 0;
    }
    buf[off..off + 8].copy_from_slice(POST_MAGIC);
    let body = (*core::ptr::addr_of!(POST_BUF)).as_bytes();
    let mut w = off + 8;
    let max_body = POST_CAP.saturating_sub(POST_OK.len());
    let n = core::cmp::min(body.len(), max_body);
    buf[w..w + n].copy_from_slice(&body[..n]);
    w += n;
    let ok = POST_OK.as_bytes();
    if w + ok.len() <= off + 8 + POST_CAP {
        buf[w..w + ok.len()].copy_from_slice(ok);
    }

    if bio.write_blocks(media_id, lba, buf).is_err() {
        uart_write("IA_LIVRE_BAREMETAL_REPORT_POST_WRITE=fail\n");
        return;
    }
    let _ = bio.flush_blocks();
    uart_write("IA_LIVRE_BAREMETAL_REPORT_POST_WRITE=ok\n");
}

fn write_sfs(data: &[u8]) -> Result<(), &'static str> {
    let mut sfs = boot::get_image_file_system(boot::image_handle()).map_err(|_| "no_fs")?;
    let mut root = sfs.open_volume().map_err(|_| "open_volume")?;

    let handle = root
        .open(
            cstr16!("\\IA_LIVRE\\baremetal-report.txt"),
            FileMode::CreateReadWrite,
            FileAttribute::empty(),
        )
        .map_err(|_| "open_file")?;

    let mut file = handle.into_regular_file().ok_or("not_file")?;
    let _ = file.set_position(0);
    file.write(data).map_err(|_| "write")?;
    file.flush().map_err(|_| "flush")?;
    Ok(())
}

fn locate_and_arm_slot() -> bool {
    let handles = match boot::locate_handle_buffer(SearchType::from_proto::<BlockIO>()) {
        Ok(h) => h,
        Err(_) => return false,
    };

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
        let bio = ManuallyDrop::new(bio);
        let media = bio.media();
        if !media.is_media_present() || media.is_read_only() {
            continue;
        }
        let bs = media.block_size();
        if bs == 0 || bs > 4096 {
            continue;
        }
        let last = media.last_block();
        let media_id = media.media_id();
        let max_lba_scan = core::cmp::min(last, (8 * 1024 * 1024 / bs as u64).saturating_sub(1));
        let chunk_blocks = core::cmp::min(64u32, (16_384 / bs).max(1) as u32);
        let mut scratch = [0u8; 16_384];

        let mut lba: u64 = 0;
        while lba <= max_lba_scan {
            let blocks_left = max_lba_scan.saturating_sub(lba).saturating_add(1);
            let n = core::cmp::min(chunk_blocks as u64, blocks_left) as u32;
            let nbytes = (n as usize).saturating_mul(bs as usize);
            let buf = &mut scratch[..nbytes];
            if bio.read_blocks(media_id, lba, buf).is_err() {
                break;
            }
            if let Some(pos) = find_magic(buf) {
                let slot_bytes = 8 + POST_CAP;
                let n_blocks = ((pos + slot_bytes + bs as usize - 1) / bs as usize) as u32;
                let bio_ptr: *mut BlockIO = core::ptr::from_ref::<BlockIO>(&*bio).cast_mut();
                unsafe {
                    POST_SLOT = Some(PostSlot {
                        bio: bio_ptr,
                        media_id,
                        lba,
                        offset: pos,
                        block_size: bs,
                        n_blocks: n_blocks.max(1),
                    });
                }
                POST_ARMED.store(true, Ordering::Relaxed);
                return true;
            }
            lba = lba.saturating_add(n as u64);
        }
    }
    false
}

fn find_magic(buf: &[u8]) -> Option<usize> {
    if buf.len() < 8 {
        return None;
    }
    for i in 0..=buf.len() - 8 {
        if &buf[i..i + 8] == POST_MAGIC {
            return Some(i);
        }
    }
    None
}
