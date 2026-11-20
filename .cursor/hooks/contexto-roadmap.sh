#!/usr/bin/env bash
# sessionStart: injeta etapa atual do ROADMAP.md e spec ativa.
# Fail open: qualquer erro → {}.
set -u

input=$(cat || true)
dir="$(cd "$(dirname "$0")" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo '{}'
  exit 0
fi

printf '%s' "$input" | python3 "$dir/contexto-roadmap.py" 2>/dev/null || echo '{}'
exit 0
