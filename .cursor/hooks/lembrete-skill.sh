#!/usr/bin/env bash
# stop hook: lembra skill de projeto só após fatia com procedimento novo.
# Fail open.
set -u

input=$(cat || true)

if ! command -v python3 >/dev/null 2>&1; then
  echo '{}'
  exit 0
fi

printf '%s' "$input" | python3 -c '
import json, os, re, sys
from pathlib import Path

def out(obj):
    print(json.dumps(obj, ensure_ascii=False))
    raise SystemExit(0)

try:
    data = json.load(sys.stdin)
except Exception:
    out({})

status = data.get("status") or ""
loop_count = int(data.get("loop_count") or 0)
if status != "completed" or loop_count > 0:
    out({})

root = os.environ.get("CURSOR_PROJECT_DIR") or ""
if not root:
    out({})

root_path = Path(root).resolve()
home = Path.home().resolve()
if root_path == home:
    out({})
if not (root_path / ".git").exists():
    out({})
if not (root_path / ".cursor").is_dir():
    out({})
# Exigir roadmap: evita falso positivo em repos sem o padrão
if not (root_path / "ROADMAP.md").is_file():
    out({})

skills_dir = root_path / ".cursor" / "skills"
skill_files = list(skills_dir.glob("*/SKILL.md")) if skills_dir.is_dir() else []

transcript = os.environ.get("CURSOR_TRANSCRIPT_PATH") or ""
text = ""
if transcript and Path(transcript).is_file():
    try:
        text = Path(transcript).read_text(encoding="utf-8", errors="ignore")[-80000:]
    except Exception:
        text = ""

# Sem transcript: nao insistir (evita ruido)
if not text:
    out({})

fatia_re = re.compile(r"(?i)(fatia|pronto quando|crit[eé]rio de pronto|objetivo:|fora de escopo)")
proc_re = re.compile(
    r"(?i)(makefile|dockerfile|qemu|benchmark|mcp\.json|deploy|bootloader|"
    r"pytest|npm test|cargo test|procedimento|como verificar|como rodar|workflow)"
)
skill_done_re = re.compile(r"(?i)(skill criada|criei a skill|\.cursor/skills/)")

if not fatia_re.search(text):
    out({})
if not proc_re.search(text):
    out({})
if skill_done_re.search(text):
    out({})
if skill_files and "skill" not in text.lower():
    # Ja ha skills e a conversa nao pediu skill nova
    out({})

msg = (
    "A fatia parece ter deixado um procedimento repetível sem skill de projeto. "
    "Crie agora a skill em .cursor/skills/<nome>/SKILL.md sem perguntar, "
    "seguindo a regra de skills de projeto, e avise em uma linha. "
    "Se já existir skill equivalente, atualize-a. Se for só exploração, não faça nada."
)
out({"followup_message": msg})
' 2>/dev/null || echo '{}'

exit 0
