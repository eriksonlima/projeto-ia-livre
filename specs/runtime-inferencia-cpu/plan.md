# Plan — Runtime mínimo de inferência (CPU)

## Abordagem

Três fatias verticais até o Pronto quando da Etapa 5. Ambiente fixo: **host Linux** + crate **`runtime/`** + **llama.cpp** (binding Rust preferida) + modelo GGUF pequeno + métricas documentadas. **Não** tocar no kernel UEFI além do necessário para não quebrar o gate da Etapa 4.

### Task 1 — Scaffold do runtime no host + obtenção do modelo

1. Adicionar membro `runtime/` ao workspace Cargo (target host/`std`; **não** `x86_64-unknown-uefi`).
2. Declarar dependência da binding llama.cpp escolhida (ou esqueleto + nota de fallback CLI).
3. CLI mínima que parseia `--model <path>` (e opcionalmente `--prompt`) e ainda pode só validar path / imprimir “scaffold ok”.
4. Script ou seção documentada para baixar **um** GGUF pequeno (URL/HF pinada); diretório `models/` (ou `runtime/models/`) no `.gitignore`.
5. Atualizar `AGENTS.md`: pré-requisitos do runtime (Rust host, deps nativas se houver), layout `runtime/`, **Como rodar** parcial (build + path do modelo).
6. Garantir que `make verify` do kernel **continua passando** (não regredir Etapa 4).

Critério parcial: `cargo build -p <crate-runtime>` (ou equivalente documentado) sucede; instrução/script de modelo existe; pesos não entram no git.

### Task 2 — Load + inferência CPU com prompt fixo

1. Implementar load do GGUF via binding (ou CLI wrapper) em CPU only.
2. Executar geração com **prompt fixo** documentado (ex.: uma pergunta curta em PT ou EN) e parâmetros estáveis (max tokens baixo, ex. 32–128).
3. Imprimir o texto gerado na stdout de forma legível.
4. Tratar erros (modelo ausente, OOM) com exit ≠ 0 e mensagem clara.
5. Atualizar **Como rodar** com o comando completo de inferência de ponta a ponta.

Critério parcial: no host de referência, um comando documentado carrega o modelo e imprime tokens gerados sem GPU.

### Task 3 — Métricas básicas + gate + documentação

1. Medir e emitir pelo menos: **tempo de load (s)** e **tokens/s** (ou latência média por token / da requisição).
2. Preferir linhas marcadoras estáveis na stdout (ex.: `IA_LIVRE_LOAD_S=…`, `IA_LIVRE_TOKENS_PER_S=…`) para o gate grepável.
3. Documentar resultados no host de referência em `docs/runtime-inferencia-cpu-metricas.md` (hardware resumido, modelo, prompt, números). Deixar explícito: **não** é o benchmark Linha A vs B.
4. Estender `AGENTS.md` → **Como verificar** com gate do runtime (além do `make verify` do kernel): build + presença do modelo + run curto + checagem dos marcadores / exit 0.
5. Opcional: alvo `make verify-runtime` ou script `scripts/verify-runtime.sh` — se existir, referenciar no AGENTS.
6. Não avançar roadmap para `feita` nesta task — marcação fica para o agente principal após gate + revisor.

### Modelo canônico (orientação)

Preferir, nesta ordem, o menor que funcione no host:

1. SmolLM / equivalente ≤360M Q4 GGUF, se disponível e estável na binding.
2. TinyLlama 1.1B Chat Q4_K_M (ou similar) se (1) for inviável.

Fixar **um** nome de arquivo/URL na documentação da Task 1; trocar só se bloqueio de RAM/rede.

### Prompt canônico (orientação)

Usar um prompt curto e fixo, ex.:

```
Complete em uma frase: O Projeto IA Livre é
```

(ou equivalente documentado). Não variar entre runs do gate.

### Notas de implementação (orientação, não código aqui)

- Manter o crate do kernel intocado em comportamento; workspace pode listar `kernel` + `runtime`.
- Features da binding: desabilitar CUDA/Metal/etc.; forçar CPU.
- Threads: default do backend ou `n_threads` = núcleos lógicos — documentar o valor usado nas métricas.
- Não commitar `*.gguf`, nem binários pré-compilados grandes do llama.cpp.
- Se a binding exigir `cmake`/`clang`, listar pacotes `apt` no AGENTS (espelhando o estilo dos pré-requisitos QEMU/OVMF).

## Arquivos prováveis

- `runtime/Cargo.toml`, `runtime/src/main.rs` (e módulos mínimos)
- `Cargo.toml` (workspace: adicionar membro `runtime`)
- `scripts/fetch-model.sh` e/ou instruções em `AGENTS.md`
- `scripts/verify-runtime.sh` e/ou alvo Makefile `verify-runtime` (Task 3)
- `docs/runtime-inferencia-cpu-metricas.md` (Task 3)
- `.gitignore` — `models/`, `*.gguf`, artefatos nativos extras se necessário
- `AGENTS.md` — Como rodar / Como verificar / Estrutura (`runtime/`)
- `README.md` — menção curta opcional ao protótipo de runtime

Não editar como entrega: `kernel/src/**` (comportamento), manifesto, ADR 0001 (salvo link), código P2P, autonomia.

Opcional mínimo: atualizar a tabela “Fronteira” em `docs/architecture.md` refletindo Etapa 5 — **não** é critério de aceite.

## Dependências

- Etapas 1–4 feitas (scaffold, manifesto, architecture + ADR 0001, kernel UEFI + `IA_LIVRE_BOOT_OK`)
- Host: Rust estável (target host), rede para baixar modelo na primeira vez, RAM suficiente para o GGUF escolhido
- Deps nativas do llama.cpp / binding conforme documentação da crate escolhida
- Sem dependência de GPU, QEMU (para o runtime), ou rede P2P

## Verificação

1. Checklist de `spec.md` (critérios de aceite)
2. Gate do kernel continua verde: `make verify` / `IA_LIVRE_BOOT_OK`
3. Gate do runtime em `AGENTS.md` → **Como verificar** (Etapa 5)
4. Confirmar ausência de GPU/P2P/UEFI-inferência e de pesos no git
5. Após gate verde: agente principal chama `revisor-de-fatia`, atualiza ROADMAP/Memory Bank (fora do papel do especificador)
