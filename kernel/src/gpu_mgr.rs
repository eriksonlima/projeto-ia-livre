//! GPU manager nativo mínimo pós-ExitBoot (Etapa 38).
//! Enum sintética + afinidade Weights/KvCache + placement Prefill/Decode.
//! Identidade `IA_LIVRE_GPU_MGR=native` — ≠ stub host E25. Sem TOKENS_PER_S.

use crate::{uart_emit_kv, uart_write};

/// QEMU de referência: 1 device lógico sintético (sem PCI/CUDA real).
const SYNTHETIC_DEVICES: u64 = 1;

/// Emite o bloco GPU manager nativo na UART COM1 (após `MEM_SCHED_OK`).
pub(crate) unsafe fn run_gpu_mgr_native() {
    uart_write("IA_LIVRE_GPU_MGR=native\n");
    uart_emit_kv("IA_LIVRE_GPU_DEVICES=", SYNTHETIC_DEVICES);
    uart_write("IA_LIVRE_GPU_DEV0_KIND=synthetic\n");

    // Afinidade: ambas as classes tipadas E19 → device 0.
    uart_write("IA_LIVRE_GPU_AFFIN_CLASS=weights\n");
    uart_emit_kv("IA_LIVRE_GPU_AFFIN_DEV=", 0);
    uart_write("IA_LIVRE_GPU_AFFIN_CLASS=kvcache\n");
    uart_emit_kv("IA_LIVRE_GPU_AFFIN_DEV=", 0);

    // Placement por fase (alinhado à demo Prefill→Decode).
    uart_write("IA_LIVRE_GPU_PLACE_PHASE=prefill\n");
    uart_write("IA_LIVRE_GPU_PLACE_HINT=device0|weights\n");
    uart_write("IA_LIVRE_GPU_PLACE_PHASE=decode\n");
    uart_write("IA_LIVRE_GPU_PLACE_HINT=device0|kvcache\n");

    uart_write("IA_LIVRE_GPU_SHARD_DOC=pipeline_layer\n");
    uart_write("IA_LIVRE_GPU_MGR_OK\n");
}
