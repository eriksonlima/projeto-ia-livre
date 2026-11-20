#!/usr/bin/env bash
# Wrapper: mesma lógica do alvo `make run`.
set -euo pipefail
cd "$(dirname "$0")/.."
exec make run "$@"
