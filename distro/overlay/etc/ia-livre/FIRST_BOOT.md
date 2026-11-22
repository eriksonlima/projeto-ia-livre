# First-boot — IA Livre Linux

## Login (live / USB)

| Campo | Valor |
|-------|--------|
| Usuário | `ialivre` |
| Senha | `ialivre` |

Autologin no TTY1 costuma entrar sozinho. Se pedir login, use a tabela acima.  
`sudo` sem senha para este usuário (lab TTY-first). Root também usa a senha `ialivre`.

## Modelos

1. PATH já inclui `/opt/ia-livre/bin` (via `/etc/profile.d/ia-livre.sh`).
2. **Não** há GGUF embutido no artefato default. Copie um `.gguf` para `/var/lib/ia-livre/models/`.
3. Comandos: `ia-livre model list` · `ia-livre model set …` · `ia-livre infer` · `ia-livre-native-tune`

Lab com pesos na ISO: `IA_LIVRE_DEBIAN_INCLUDE_GGUF=1` no build.
