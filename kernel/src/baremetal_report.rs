//! Canal padrão bare-metal: flush de marcadores/métricas na ESP (Etapa 73 / ADR 0025).
//! Escrita via SimpleFileSystem **antes** de ExitBootServices.

use uefi::boot;
use uefi::cstr16;
use uefi::proto::media::file::{File, FileAttribute, FileMode};

use crate::LineSink;

/// Capacidade do buffer pré-exit (marcadores + métricas).
pub(crate) const REPORT_CAP: usize = 12_288;

const HEADER: &str = "\
# IA_LIVRE_BAREMETAL_REPORT_V1\n\
# MEDIA=usb_esp_file\n\
# WRITTEN_PRE_EXIT=1\n";

const REPORT_OK: &str = "IA_LIVRE_BAREMETAL_REPORT_OK\n";

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

/// Grava o relatório na ESP; emite OK/FAIL no sink. Não bloqueia o boot.
pub(crate) fn flush_report(sink: &mut LineSink<'_>) {
    let Some(buf) = sink.report.as_ref() else {
        sink.emit_console_only("IA_LIVRE_BAREMETAL_REPORT_FAIL=no_buffer\n");
        return;
    };

    // Monta payload: cabeçalho + buffer + OK (sem reentrar no buffer).
    let body = buf.as_bytes();
    let mut payload = [0u8; HEADER.len() + REPORT_CAP + 64];
    let mut off = 0usize;
    payload[off..off + HEADER.len()].copy_from_slice(HEADER.as_bytes());
    off += HEADER.len();
    payload[off..off + body.len()].copy_from_slice(body);
    off += body.len();
    payload[off..off + REPORT_OK.len()].copy_from_slice(REPORT_OK.as_bytes());
    off += REPORT_OK.len();
    let out = &payload[..off];

    match write_sfs(out) {
        Ok(()) => {
            sink.emit(REPORT_OK);
        }
        Err(code) => {
            sink.emit_console_only("IA_LIVRE_BAREMETAL_REPORT_FAIL=");
            sink.emit_console_only(code);
            sink.emit_console_only("\n");
        }
    }
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
