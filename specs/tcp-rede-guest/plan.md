# Plan — Stack TCP Rede nativa no guest

## Abordagem

1. **Medir A e fechar B** — inventário do kernel pós-Exit (UART-only; ausência NIC/virtio/TCP); registrar por que A não cabe na fatia; **escolher B**.
2. **Contrato + ADR** — ADR `0024` (TCP guest ainda inviável); estender `docs/rede-bridge-nativo.md` e/ou criar `docs/rede-tcp-guest.md`; fixar marcador `IA_LIVRE_NET_GUEST_BLOCK=no_tcp_post_exit` (ou nome equivalente) e nome do gate.
3. **Runner + gate** — emitir bloqueio honesto no caminho B (reusar evidência/bridge E52 + âncora `TASK_OK`); target `verify-rede-guest` **ou** estágio em `verify-rede-bridge`; anti-fraude (`NET_NATIVE_OK` sem stack → falha); regressão `verify-node` + `verify-rede-bridge`; `AGENTS.md` + README (`readme-por-fatia`).

## Arquivos prováveis

- `docs/adr/0024-tcp-rede-guest-inviavel.md` (novo; número confirma na Task 1 se 0024 ainda livre)
- `docs/rede-tcp-guest.md` (novo, opcional) **e/ou** extensão de `docs/rede-bridge-nativo.md`
- `docs/adr/0019-rede-bridge-uefi-host.md` (ponte: adiamento → inviabilidade E66)
- `docs/rede-ia-livre-v1.md` — ponte curta se necessário
- `scripts/run-rede-bridge.sh` e/ou `scripts/run-rede-guest.sh` (nome na Task 1)
- `scripts/verify-rede-bridge.sh` e/ou `scripts/verify-rede-guest.sh`
- `Makefile` — target do gate E66
- `AGENTS.md` — Como verificar
- `README.md` — avaliar (`readme-por-fatia`)
- `docs/glossario.md` — se `NET_GUEST_BLOCK` precisar entrada
- `kernel/` — **não** implementar stack TCP; só menção documental / probe se barato e não teatral

## Dependências

- E11 feita (pós-Exit + UART)
- E52 / ADR 0019 feitas (bridge `NET_BRIDGE_*`)
- E23/E51 (`ia-livre-node` + `TASK_OK`) para âncora host
- Sem NIC/driver no kernel — premissa medida para desfecho B

## Verificação

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Contrato + ADR
test -f docs/adr/0024-tcp-rede-guest-inviavel.md   # ou path fixado na Task 1
test -f docs/rede-bridge-nativo.md

# Gate E66 (nome fixado na Task 1)
# make verify-rede-guest
#   OU estágio documentado em make verify-rede-bridge
# Esperado: NET_GUEST_BLOCK=… + NET_BRIDGE_OK (caminho B); sem NET_NATIVE_OK falso

# Regressões ADR 0001 / E52
make verify-rede-bridge
make verify-node   # sem QEMU / sem exigir SO

# Anti-fraude: NET_NATIVE_OK sem stack → falha do gate E66
```
