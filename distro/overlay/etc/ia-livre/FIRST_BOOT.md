# First-boot — IA Livre Linux

## Login (live / USB)

| Campo | Valor |
|-------|--------|
| Usuário | `ialivre` |
| Senha | `ialivre` |

Autologin no TTY1 costuma entrar sozinho. Se pedir login, use a tabela acima.  
`sudo` sem senha para este usuário (lab TTY-first). Root também usa a senha `ialivre`.

## Modelos

A ISO **default não traz** GGUF (~638 MiB) — economiza espaço no pendrive.

Com rede no live:

```bash
ia-livre model catalog        # lista IDs baixáveis (tamanho + nota)
ia-livre model fetch tinyllama   # ou: phi2 | qwen25-05b | smollm2-360 | …
ia-livre infer
```

Ou manual:

```bash
sudo apt update && sudo apt install -y curl   # se curl ainda não estiver na imagem
curl -fL -o /var/lib/ia-livre/models/meu.gguf 'https://…/arquivo.gguf'
ia-livre model set meu.gguf
```

Lab com pesos já na ISO: `IA_LIVRE_DEBIAN_INCLUDE_GGUF=1` no build do host.
