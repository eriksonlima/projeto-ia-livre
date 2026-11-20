# Licenças de terceiros (aviso)

O código de **1ª parte** do Projeto IA Livre (crates `kernel`, `runtime`, `node`, `agent` e documentação do repositório) está sob **Apache-2.0** — ver [`LICENSE`](../LICENSE), [`NOTICE`](../NOTICE) e ADR [`0007`](adr/0007-licencas-por-componente.md).

Dependências e artefatos de **terceiros** **não** são relicenciados pelo projeto. Redistribuidores devem respeitar as licenças upstream. Lista **não exaustiva** das mais relevantes:

| Componente | Uso no projeto | Nota |
|------------|----------------|------|
| `llama-cpp-2` / llama.cpp | `runtime/` (inferência) | Licença(s) do binding e do llama.cpp upstream |
| `uefi` (uefi-rs) | `kernel/` (bootstrap UEFI) | Licença do crate upstream |
| Demais crates Cargo | workspace | Ver `cargo tree` / metadados de cada crate |
| Pesos GGUF em `models/` | runtime / agent | Origem Hugging Face / autores do modelo — **não** são código do Projeto IA Livre |

Este documento **não** substitui os textos de licença dos projetos citados nem um parecer jurídico.
