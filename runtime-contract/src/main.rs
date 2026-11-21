//! Shim host do contrato nativo (Etapa 20).
//!
//! Exerce alloc tipado Weights/KvCache e hints Prefill→Decode via stub em memória.
//! **Não** é Linha B, **não** carrega GGUF, **não** emite TOKENS_PER_S, **não** prova a hipótese.
//! Ver `docs/runtime-contrato-nativo.md`.

use std::alloc::{alloc, dealloc, Layout};
use std::ptr::NonNull;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum MemClass {
    Weights,
    KvCache,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Phase {
    Prefill,
    Decode,
}

struct TypedRegion {
    class: MemClass,
    ptr: NonNull<u8>,
    layout: Layout,
}

impl TypedRegion {
    fn alloc(class: MemClass, bytes: usize) -> Self {
        let layout = Layout::from_size_align(bytes, 8).expect("layout");
        let ptr = unsafe { alloc(layout) };
        let ptr = NonNull::new(ptr).expect("oom");
        // Toque mínimo: escreve um byte por classe (evidência de região utilizável).
        unsafe {
            *ptr.as_ptr() = match class {
                MemClass::Weights => 0x57,  // 'W'
                MemClass::KvCache => 0x4B,  // 'K'
            };
        }
        Self { class, ptr, layout }
    }
}

impl Drop for TypedRegion {
    fn drop(&mut self) {
        unsafe { dealloc(self.ptr.as_ptr(), self.layout) };
    }
}

/// Stub do contrato: no host não há kernel E19; políticas ficam no processo.
struct HostContractShim {
    phase: Option<Phase>,
}

impl HostContractShim {
    fn new() -> Self {
        Self { phase: None }
    }

    fn mem_alloc(&mut self, class: MemClass, bytes: usize) -> TypedRegion {
        TypedRegion::alloc(class, bytes)
    }

    fn set_phase(&mut self, phase: Phase) {
        self.phase = Some(phase);
        match phase {
            Phase::Prefill => println!("IA_LIVRE_CONTRACT_PHASE=Prefill"),
            Phase::Decode => println!("IA_LIVRE_CONTRACT_PHASE=Decode"),
        }
    }
}

fn main() {
    println!("IA_LIVRE_CONTRACT_BACKEND=host_shim");

    let mut shim = HostContractShim::new();

    let weights = shim.mem_alloc(MemClass::Weights, 4096);
    assert_eq!(weights.class, MemClass::Weights);
    println!("IA_LIVRE_CONTRACT_ALLOC_WEIGHTS=OK");

    let kv = shim.mem_alloc(MemClass::KvCache, 2048);
    assert_eq!(kv.class, MemClass::KvCache);
    println!("IA_LIVRE_CONTRACT_ALLOC_KVCACHE=OK");

    shim.set_phase(Phase::Prefill);
    shim.set_phase(Phase::Decode);

    // Mantém regiões vivas até o fim da sequência (drop no fim de main).
    drop(weights);
    drop(kv);

    println!("IA_LIVRE_RUNTIME_CONTRACT_OK");
}
