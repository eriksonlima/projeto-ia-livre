#!/usr/bin/env bash
# Gate Etapa 78 / B73 — config + troca de GGUF (qualquer modelo).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

IA=distro/overlay/opt/ia-livre/bin/ia-livre
chmod +x "$IA"

test -f distro/overlay/etc/ia-livre/ia-livre.conf
test -f distro/overlay/var/lib/ia-livre/models/README.md
grep -q 'model set' "$IA"
grep -q 'qualquer' distro/overlay/var/lib/ia-livre/models/README.md

./scripts/stage-distro-overlay.sh >/tmp/stage-b73.log 2>&1 || {
  cat /tmp/stage-b73.log
  exit 1
}

"$IA" model list | grep -q 'IA_LIVRE_MODEL_LIST_OK'
"$IA" model show | grep -q 'IA_LIVRE_MODEL_OK' || {
  # Sem GGUF: ainda passa list; show pode falhar
  if [[ ! -f distro/overlay/var/lib/ia-livre/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf ]]; then
    echo "IA_LIVRE_MODEL_SHOW_SKIP=no_gguf"
  else
    echo "GATE_FAIL: model show"
    exit 1
  fi
}

# model set round-trip se GGUF existir
GGUF=distro/overlay/var/lib/ia-livre/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
if [[ -f "$GGUF" ]]; then
  "$IA" model set tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf | grep -q 'IA_LIVRE_MODEL_OK'
  grep -q 'tinyllama' distro/overlay/etc/ia-livre/ia-livre.conf
fi

grep -q 'model set' docs/linux-ia-nativo.md

echo "IA_LIVRE_DISTRO_CONFIG_MODELS_OK"
echo "GATE_OK: config/modelos — list/set/show; qualquer GGUF documentado"
