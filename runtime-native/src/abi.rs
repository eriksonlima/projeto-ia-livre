//! ABI mínima v1 (freestanding) — Etapa 71.
//! Superfície: version id + classes/fases alinhadas a E19 + handshake `prepare`.
//! Motor de inferência permanece nesta crate (ADR 0001 / 0010).

/// Versão do contrato ABI mínima kernel↔runtime-native.
pub const ABI_VERSION: u32 = 1;

/// Classes de memória do contrato (espelho E19 / ADR 0003).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u8)]
pub enum AbiMemClass {
    Weights = 1,
    KvCache = 2,
}

/// Fases mínimas do scheduler (espelho E19).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u8)]
pub enum AbiPhase {
    Prefill = 1,
    Decode = 2,
    Idle = 3,
}

/// Relatório do handshake ABI (sem executar Prefill/Decode guest).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct AbiHandshake {
    pub version: u32,
    pub mem_weights: u8,
    pub mem_kv: u8,
    pub phase_prefill: u8,
    pub phase_decode: u8,
}

/// Prova a superfície mínima v1 (constantes + discriminantes).
pub fn abi_handshake() -> AbiHandshake {
    AbiHandshake {
        version: ABI_VERSION,
        mem_weights: AbiMemClass::Weights as u8,
        mem_kv: AbiMemClass::KvCache as u8,
        phase_prefill: AbiPhase::Prefill as u8,
        phase_decode: AbiPhase::Decode as u8,
    }
}

/// `true` se o handshake casa com ABI v1 documentada.
pub fn abi_surface_ok(h: &AbiHandshake) -> bool {
    h.version == 1
        && h.mem_weights == AbiMemClass::Weights as u8
        && h.mem_kv == AbiMemClass::KvCache as u8
        && h.phase_prefill == AbiPhase::Prefill as u8
        && h.phase_decode == AbiPhase::Decode as u8
        && h.phase_prefill != h.phase_decode
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn abi_v1_handshake() {
        let h = abi_handshake();
        assert!(abi_surface_ok(&h), "ABI v1 surface");
        assert_eq!(h.version, ABI_VERSION);
        assert_eq!(ABI_VERSION, 1);
    }
}
