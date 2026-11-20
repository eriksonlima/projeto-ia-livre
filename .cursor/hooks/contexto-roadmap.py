#!/usr/bin/env python3
"""sessionStart: PATH + roadmap + activeContext."""
import json
import os
import re
import sys
from pathlib import Path


def out(obj):
    print(json.dumps(obj, ensure_ascii=False))
    raise SystemExit(0)


def parse_roadmap(text):
    blocks = re.split(r"(?m)^##\s+", text)
    etapas = []
    for block in blocks[1:]:
        lines = block.strip().splitlines()
        if not lines:
            continue
        title = lines[0].strip()
        body = "\n".join(lines[1:])
        status_m = re.search(r"(?im)^Status:\s*(\S+)", body)
        issue_m = re.search(r"(?im)^Issue:\s*(.+)$", body)
        spec_m = re.search(r"(?im)^Spec:\s*(.+)$", body)
        status = (status_m.group(1).strip().lower() if status_m else "pendente")
        etapas.append(
            {
                "title": title,
                "status": status,
                "issue": (issue_m.group(1).strip() if issue_m else ""),
                "spec": (spec_m.group(1).strip() if spec_m else ""),
            }
        )
    return etapas


def summarize_active(path: Path) -> str:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""
    # Keep it short for context injection
    lines = []
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        if s.startswith("- ") or s.startswith("* "):
            lines.append(s)
        if len(lines) >= 8:
            break
    return " | ".join(lines) if lines else text.strip()[:400]


def main():
    try:
        json.load(sys.stdin)
    except Exception:
        pass

    home = Path.home().resolve()
    local_bin = str(home / ".local" / "bin")
    path = os.environ.get("PATH") or ""
    if local_bin not in path.split(":"):
        path = f"{local_bin}:{path}"

    result = {"env": {"PATH": path, "HOME": str(home)}}

    root = os.environ.get("CURSOR_PROJECT_DIR") or ""
    if not root:
        out(result)

    root_path = Path(root).resolve()
    if root_path == home:
        out(result)

    ctx_parts = []

    roadmap = root_path / "ROADMAP.md"
    if roadmap.is_file():
        try:
            text = roadmap.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            text = ""
        etapas = parse_roadmap(text) if text else []
        if etapas:
            atual = next((e for e in etapas if e["status"] == "em_andamento"), None)
            proximas = [e for e in etapas if e["status"] == "pendente"]
            feitas = [e for e in etapas if e["status"] == "feita"]
            faltam = len([e for e in etapas if e["status"] not in ("feita",)])
            lines = ["[Roadmap do projeto]"]
            if atual:
                lines.append(f"Etapa atual: {atual['title']} (em_andamento)")
                if atual["spec"] and not atual["spec"].startswith("_"):
                    lines.append(f"Spec: {atual['spec']}")
                if atual["issue"] and not atual["issue"].startswith("_"):
                    lines.append(f"Issue: {atual['issue']}")
            else:
                lines.append("Nenhuma etapa em_andamento.")
            if proximas:
                lines.append(f"Próxima: {proximas[0]['title']}")
            lines.append(
                f"Progresso: {len(feitas)} feita(s), {faltam} restante(s) de {len(etapas)}."
            )
            ctx_parts.append("\n".join(lines))

    active = root_path / "memory-bank" / "activeContext.md"
    if active.is_file():
        summary = summarize_active(active)
        if summary:
            ctx_parts.append("[Memory Bank activeContext]\n" + summary)

    if ctx_parts:
        ctx_parts.append(
            "Trabalhe só a etapa em_andamento. Leia AGENTS.md, memory-bank/activeContext.md e a spec ativa."
        )
        result["additional_context"] = "\n\n".join(ctx_parts)

    out(result)


if __name__ == "__main__":
    main()
