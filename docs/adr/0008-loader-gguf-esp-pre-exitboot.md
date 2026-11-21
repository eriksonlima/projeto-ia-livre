# ADR 0008 — Loader GGUF nativo mínimo via ESP (pré-ExitBoot)

- Status: aceita
- Data: 2026-11-20

## Contexto

A Etapa 21 deixou a Linha B com `GGUF_NATIVE_LOADER=absent` e `B_BLOCK=no_gguf_path`: o harness aponta o alvo canônico, mas o guest UEFI não lê bytes do GGUF. Sem I/O mínimo, a hipótese A vs B permanece `INCONCLUSIVO`.

O boot já usa ESP FAT (`make esp` + QEMU `fat:rw:build/esp`). SimpleFileSystem UEFI tipicamente só está disponível sob **Boot Services**.

## Decisão

1. **Mecanismo canônico v1:** colocar um artefato GGUF (arquivo completo **ou** prefixo/cabeçalho documentado) no ESP no host; no guest, abrir via `SimpleFileSystem` **antes** de `ExitBootServices`, ler magic `GGUF` + bytes mínimos, copiar para buffer/`Weights`, emitir marcadores serial.
2. **Mínimo aceitável:** cabeçalho/prefixo (ex. 4 KiB em `IA_LIVRE/gguf.hdr`) — **não** exige mapear ~638 MiB na RAM QEMU (`-m 256M`).
3. **Rejeitado no v1:** fw_cfg e virtio-blk/fs como caminho obrigatório (só pivô com nova ADR se ESP falhar no host de referência).
4. **Proibido:** emitir `TOKENS_PER_S` / `LOAD_S` / `LOAD_KIND=gguf` com geração; declarar hipótese comprovada só porque o loader leu bytes.
5. **Estado harness:** `GGUF_NATIVE_LOADER` ≠ `absent` (ex. `esp_header`); `GGUF_STATUS=header_ok` (ou equivalente); `B_BLOCK=no_gguf_infer` enquanto não houver geração (path de arquivo desbloqueado; inferência ainda ausente).

## Consequências

- Etapa 26 / B20 implementa o contrato acima.
- Inferência / `TOKENS_PER_S` em B fica para etapa seguinte (B21).
- Gate `verify-harness` deixa de exigir o trio E21 (`absent` + `no_gguf_path` + `blocked` puro) como sucesso.
