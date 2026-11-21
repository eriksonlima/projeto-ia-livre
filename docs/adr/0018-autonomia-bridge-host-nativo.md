# ADR 0018 — Bridge host↔nativo (autonomia sem agente no guest)

- Status: aceita
- Data: 2026-11-21

## Contexto

Etapa 49: autonomia mínima “no caminho nativo”. Agente UEFI no guest é inviável (sem shell/rede/FS; ADR 0001). `agent/` host já consome `ia-livre-runtime` — **não** prova nativo.

## Decisão

1. **Bridge no host** valida evidência serial/log do runtime nativo (QEMU BlockIO E44 ou metal E48) e emite `IA_LIVRE_BRIDGE_*`.
2. Agente permanece no host (allowlist E40); bridge **não** embute agente no kernel.
3. Distinguir fontes: `BRIDGE_NATIVE_SRC=blockio` vs `metal_block`.
4. Gate aditivo; `verify-agent` continua independente do SO.

## Rejeitado

- Agente no kernel; fingir host-llama como nativo; shell irrestrito.

## Consequências

- Contrato: [`docs/autonomia-bridge-nativo.md`](../autonomia-bridge-nativo.md).
- Gate: `make verify-autonomia-bridge`.
