# ADR 0007 — Licenças por componente (Apache-2.0)

- Status: aceita
- Data: 2026-11-20

## Contexto

O manifesto registrava preferência «Apache 2.0 para infraestrutura; GPLv3 onde preservação das liberdades for prioridade» ainda como **decisão a confirmar**. Em [`docs/architecture.md`](../architecture.md) as «licenças definitivas por componente» estavam abertas. O repositório não tinha `LICENSE` na raiz nem campo `license` nos crates.

Sem registro, contribuidores e redistribuidores não sabem sob qual SPDX o código de 1ª parte do Projeto IA Livre é oferecido.

**Nota:** esta ADR é **decisão do projeto**, não parecer jurídico. Revisão jurídica futura pode ajustar. Compliance com licenças de **terceiros** no binário/distribuição permanece obrigação do redistribuidor.

## Decisão

1. **Código e docs de 1ª parte** sob **Apache License 2.0** (SPDX: `Apache-2.0`):

| Componente | Path | Licença |
|------------|------|---------|
| Kernel IA Livre | `kernel/` | Apache-2.0 |
| Runtime de inferência | `runtime/` | Apache-2.0 |
| Nó Rede IA Livre | `node/` | Apache-2.0 |
| Ambiente de autonomia | `agent/` | Apache-2.0 |
| Documentação / textos institucionais do repo | `docs/` (+ README/AGENTS/specs de projeto) | Apache-2.0 |

2. **GPLv3:** **não** aplicada a nenhum componente de 1ª parte nesta etapa. Motivo: todos os listados são infraestrutura / documentação alinhados à preferência «Apache 2.0 para infraestrutura» do manifesto; dualismo Apache+GPL aumenta complexidade sem ganho claro agora. Se um artefato futuro exigir copyleft, nova ADR/etapa com justificativa.
3. **Arquivo canônico:** `LICENSE` na raiz (texto Apache-2.0); aviso de terceiros em `NOTICE` e/ou `docs/licencas-terceiros.md` (Task 2).
4. **Metadados Cargo:** `license = "Apache-2.0"` nos crates do workspace (Task 2).
5. **Terceiros:** `llama-cpp-2`/llama.cpp, `uefi`, e demais deps **não** são relicenciadas; mantêm licenças próprias.
6. **Pesos GGUF** em `models/`: não são código do projeto; origens/licenças próprias (política do manifesto).

### Rejeitado

- Relicenciar deps de terceiros sob Apache-2.0 do projeto
- GPLv3 «por precaução» sem justificativa de componente
- Dual-license Apache+GPL nesta etapa
- Fingir que a ADR dispensa compliance de terceiros na distribuição

## Consequências

### Positivas

- Clareza SPDX para contribuidores e redistribuidores
- Fecha a decisão aberta de architecture e confirma o manifesto
- Compatível com uso em infraestrutura e combinação com muitas deps permissivas

### Negativas

- Quem preferiria copyleft forte (GPLv3) no kernel/SO precisa de etapa futura com debate
- Ainda exige disciplina de NOTICE/atribuição para deps (não resolvido só pelo SPDX do crate)

## O que não fica decidido

- Parecer jurídico formal
- Compliance fino de cada dep em cada forma de distribuição (binário, container, imagem ESP)
- Relicenciamento futuro de algum componente para GPLv3
- Licença de modelos/pesos de terceiros (já fora do mapa de crates)
