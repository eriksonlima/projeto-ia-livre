//! Observabilidade mínima pré-ExitBoot (Etapa 37).
//! GOP fill+texto bitmap, fallback SimpleTextInput. Sem desktop / sem TOKENS_PER_S.

use uefi::boot;
use uefi::proto::console::gop::{BltOp, BltPixel, BltRegion, GraphicsOutput, PixelFormat};
use uefi::proto::console::text::Input;

use crate::{format_u64, LineSink};

const FILL_R: u8 = 0x12;
const FILL_G: u8 = 0x24;
const FILL_B: u8 = 0x48;
const TEXT_R: u8 = 0xE8;
const TEXT_G: u8 = 0xF0;
const TEXT_B: u8 = 0xFF;
const OBS_TEXT: &[u8] = b"IA Livre";
const GLYPH_W: usize = 8;
const GLYPH_H: usize = 8;
const SCALE: usize = 2;
/// Poll input: 20 × 100 ms ≈ 2 s (fallback; não bloqueia além disso).
const INPUT_POLL_ITERS: usize = 20;
const INPUT_STALL_US: usize = 100_000;

/// Roda observabilidade e emite marcadores na serial UEFI.
pub(crate) fn run_observability(sink: &mut LineSink<'_>) {
    if try_gop(sink) {
        sink.emit("IA_LIVRE_OBS_MODE=gop\n");
        sink.emit("IA_LIVRE_OBS_OK\n");
        return;
    }
    if try_input(sink) {
        sink.emit("IA_LIVRE_OBS_MODE=input\n");
        sink.emit("IA_LIVRE_OBS_OK\n");
        return;
    }
    sink.emit("IA_LIVRE_OBS_MODE=skip\n");
}

fn try_gop(sink: &mut LineSink<'_>) -> bool {
    let handle = match boot::get_handle_for_protocol::<GraphicsOutput>() {
        Ok(h) => h,
        Err(_) => return false,
    };
    let mut gop = match boot::open_protocol_exclusive::<GraphicsOutput>(handle) {
        Ok(g) => g,
        Err(_) => return false,
    };

    let info = gop.current_mode_info();
    let (width, height) = info.resolution();
    if width == 0 || height == 0 {
        return false;
    }

    if gop
        .blt(BltOp::VideoFill {
            color: BltPixel::new(FILL_R, FILL_G, FILL_B),
            dest: (0, 0),
            dims: (width, height),
        })
        .is_err()
    {
        return false;
    }

    if !draw_text(&mut gop, 32, 32) {
        return false;
    }

    emit_gop_mode(sink, width as u64, height as u64);
    sink.emit(pixel_format_marker(info.pixel_format()));
    sink.emit("IA_LIVRE_GOP_OK\n");
    true
}

fn try_input(sink: &mut LineSink<'_>) -> bool {
    let handle = match boot::get_handle_for_protocol::<Input>() {
        Ok(h) => h,
        Err(_) => return false,
    };
    let mut input = match boot::open_protocol_exclusive::<Input>(handle) {
        Ok(i) => i,
        Err(_) => return false,
    };

    // Poll curto: tecla opcional; sucesso = protocolo utilizável.
    let mut saw_key = false;
    for _ in 0..INPUT_POLL_ITERS {
        match input.read_key() {
            Ok(Some(_)) => {
                saw_key = true;
                break;
            }
            Ok(None) => boot::stall(INPUT_STALL_US),
            Err(_) => return false,
        }
    }
    let _ = saw_key;
    sink.emit("IA_LIVRE_INPUT_OK\n");
    true
}

fn draw_text(gop: &mut GraphicsOutput, origin_x: usize, origin_y: usize) -> bool {
    let (fb_w, fb_h) = gop.current_mode_info().resolution();
    let text_w = OBS_TEXT.len() * GLYPH_W * SCALE;
    let text_h = GLYPH_H * SCALE;
    if origin_x.saturating_add(text_w) > fb_w || origin_y.saturating_add(text_h) > fb_h {
        return false;
    }

    // 8 chars × 8 × 2 × 8 × 2 = 2048 px
    const MAX_PX: usize = 8 * GLYPH_W * SCALE * GLYPH_H * SCALE;
    let mut buf = [BltPixel::new(FILL_R, FILL_G, FILL_B); MAX_PX];
    let bg = BltPixel::new(FILL_R, FILL_G, FILL_B);
    let fg = BltPixel::new(TEXT_R, TEXT_G, TEXT_B);

    for (ci, &ch) in OBS_TEXT.iter().enumerate() {
        let rows = glyph(ch);
        for row in 0..GLYPH_H {
            let bits = rows[row];
            for col in 0..GLYPH_W {
                let on = (bits >> (7 - col)) & 1 == 1;
                let px = if on { fg } else { bg };
                for sy in 0..SCALE {
                    for sx in 0..SCALE {
                        let x = ci * GLYPH_W * SCALE + col * SCALE + sx;
                        let y = row * SCALE + sy;
                        buf[y * text_w + x] = px;
                    }
                }
            }
        }
    }

    gop.blt(BltOp::BufferToVideo {
        buffer: &buf[..text_w * text_h],
        src: BltRegion::Full,
        dest: (origin_x, origin_y),
        dims: (text_w, text_h),
    })
    .is_ok()
}

fn emit_gop_mode(sink: &mut LineSink<'_>, w: u64, h: u64) {
    let mut num_w = [0u8; 20];
    let mut num_h = [0u8; 20];
    let dw = format_u64(w, &mut num_w);
    let dh = format_u64(h, &mut num_h);
    let mut line = [0u8; 64];
    let prefix = b"IA_LIVRE_GOP_MODE=";
    let mut len = 0usize;
    for &b in prefix {
        line[len] = b;
        len += 1;
    }
    for b in dw.bytes() {
        line[len] = b;
        len += 1;
    }
    line[len] = b'x';
    len += 1;
    for b in dh.bytes() {
        line[len] = b;
        len += 1;
    }
    line[len] = b'\n';
    len += 1;
    sink.emit(core::str::from_utf8(&line[..len]).unwrap());
}

fn pixel_format_marker(fmt: PixelFormat) -> &'static str {
    match fmt {
        PixelFormat::Rgb => "IA_LIVRE_GOP_PIXEL_FORMAT=rgb\n",
        PixelFormat::Bgr => "IA_LIVRE_GOP_PIXEL_FORMAT=bgr\n",
        PixelFormat::Bitmask => "IA_LIVRE_GOP_PIXEL_FORMAT=bitmask\n",
        PixelFormat::BltOnly => "IA_LIVRE_GOP_PIXEL_FORMAT=blt_only\n",
    }
}

/// Glyphs 8×8 ASCII mínimo para `IA Livre`.
fn glyph(c: u8) -> [u8; 8] {
    match c {
        b'I' => [
            0b01111100, 0b00010000, 0b00010000, 0b00010000, 0b00010000, 0b00010000, 0b00010000,
            0b01111100,
        ],
        b'A' => [
            0b00010000, 0b00101000, 0b01000100, 0b01000100, 0b01111100, 0b01000100, 0b01000100,
            0b01000100,
        ],
        b'L' => [
            0b01000000, 0b01000000, 0b01000000, 0b01000000, 0b01000000, 0b01000000, 0b01000000,
            0b01111110,
        ],
        b'i' => [
            0b00000000, 0b00010000, 0b00000000, 0b00110000, 0b00010000, 0b00010000, 0b00010000,
            0b00111000,
        ],
        b'v' => [
            0b00000000, 0b00000000, 0b01000100, 0b01000100, 0b01000100, 0b00101000, 0b00101000,
            0b00010000,
        ],
        b'r' => [
            0b00000000, 0b00000000, 0b01011100, 0b01100010, 0b01000000, 0b01000000, 0b01000000,
            0b01000000,
        ],
        b'e' => [
            0b00000000, 0b00000000, 0b00111000, 0b01000100, 0b01111100, 0b01000000, 0b01000100,
            0b00111000,
        ],
        b' ' => [0; 8],
        _ => [0b11111111; 8],
    }
}
