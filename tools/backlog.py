#!/usr/bin/env python3
"""
backlog.py: builds docs/planejamento/BACKLOG.md from the properties (frontmatter) of the
epics, stories, ADRs and bugs in docs/. Replaces the dashboards of the old vault.

The documents are written in Portuguese, so their frontmatter keys (titulo, epico, pontos...)
and the generated BACKLOG.md stay in Portuguese; only this code is in English.

Usage:
    python3 tools/backlog.py           # rebuilds the file
    python3 tools/backlog.py --check   # only checks whether it is up to date (used by the CI)

On Windows, use `py` instead of `python3`. Uses only the standard library (Python 3.8+).
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
PLANNING = DOCS / "planejamento"
OUTPUT = PLANNING / "BACKLOG.md"

PRIORITY_ORDER = {"must": 0, "should": 1, "could": 2, "wont": 3}
STORY_SECTIONS = [
    ("Em andamento e em revisão", {"em-andamento", "revisao"}),
    ("Prontas para começar", {"pronto"}),
    ("Backlog", {"backlog", "ideia"}),
    ("Concluídas", {"concluido"}),
]


def read_frontmatter(path: Path) -> dict:
    """Reads the `---` block at the top of the file as key: value pairs (simple format, no nested lists)."""
    text = path.read_text(encoding="utf-8")
    data: dict = {"_file": path}
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            for line in text[3:end].splitlines():
                if ":" not in line or line.lstrip().startswith("#"):
                    continue
                key, _, value = line.partition(":")
                data[key.strip()] = value.strip().strip('"').strip("'")
    if not data.get("titulo"):
        title = re.search(r"^# (.+)$", text, flags=re.MULTILINE)
        if title:
            data["titulo"] = title.group(1).split("·", 1)[-1].strip()
    return data


def load(folder: Path, prefix: str) -> list:
    """Every `PREFIX-*.md` file in the folder that has an `id`, sorted by id."""
    if not folder.exists():
        return []
    items = [read_frontmatter(p) for p in sorted(folder.glob(f"{prefix}-*.md"))]
    return sorted((i for i in items if i.get("id")), key=lambda i: i["id"])


def cell(value) -> str:
    """Text that is safe inside a Markdown table cell."""
    return str(value).replace("|", "\\|") if value not in (None, "") else "—"


def link(item: dict) -> str:
    """Link relative to BACKLOG.md, as `[ID · Title](path)`."""
    target = Path(os.path.relpath(item["_file"], OUTPUT.parent)).as_posix()
    return f"[{item['id']} · {cell(item.get('titulo', ''))}]({target})"


def points(item: dict) -> int:
    try:
        return int(item.get("pontos") or 0)
    except ValueError:
        return 0


def table(header: list, rows: list) -> str:
    if not rows:
        return "_Nada por aqui._\n"
    out = ["| " + " | ".join(header) + " |", "|" + " --- |" * len(header)]
    out += ["| " + " | ".join(cell(c) for c in row) + " |" for row in rows]
    return "\n".join(out) + "\n"


def build() -> str:
    epics = load(PLANNING / "epicos", "EP")
    stories = load(PLANNING / "historias", "US")
    adrs = load(DOCS / "arquitetura" / "adr", "ADR")
    bugs = load(DOCS / "dev" / "bugs", "BUG")

    parts = [
        "<!-- Gerado por tools/backlog.py. Não edite à mão: mude os arquivos e rode o script. -->",
        "",
        "# Backlog",
        "",
        "Visão geral do planejamento, montada a partir das propriedades de cada arquivo em `docs/`.",
        "Fluxo das histórias: `backlog` → `pronto` → `em-andamento` → `revisao` → `concluido` (ou `cancelado`).",
        "Regras de cada passagem em [Definições de Pronto](DEFINICOES-DE-PRONTO.md).",
        "",
    ]

    rows = []
    for epic in epics:
        its_stories = [s for s in stories if s.get("epico") == epic["id"]]
        done = [s for s in its_stories if s.get("status") == "concluido"]
        progress = (
            f"{len(done)}/{len(its_stories)} histórias · {sum(map(points, done))}/{sum(map(points, its_stories))} pts"
            if its_stories
            else "sem histórias"
        )
        rows.append([link(epic), epic.get("status"), epic.get("prioridade"), epic.get("marco"), progress])
    parts += ["## Épicos", "", table(["Épico", "Status", "Prioridade", "Marco", "Progresso"], rows)]

    for title, statuses in STORY_SECTIONS:
        selected = [s for s in stories if s.get("status") in statuses]
        selected.sort(key=lambda s: (PRIORITY_ORDER.get(s.get("prioridade", ""), 9), s["id"]))
        rows = [[link(s), s.get("status"), s.get("epico"), s.get("prioridade"), points(s) or "?"] for s in selected]
        parts += [f"## {title}", "", table(["História", "Status", "Épico", "Prioridade", "Pts"], rows)]

    incomplete = [
        s
        for s in stories
        if s.get("status") not in {"concluido", "cancelado"} and (not s.get("epico") or not points(s))
    ]
    if incomplete:
        parts += ["## Histórias sem épico ou sem estimativa", "", *(f"- {link(s)}" for s in incomplete), ""]

    parts += ["## Decisões (ADRs)", "", table(["ADR", "Status"], [[link(a), a.get("status")] for a in adrs])]

    open_bugs = [b for b in bugs if b.get("status") not in {"resolvido", "fechado"}]
    rows = [[link(b), b.get("severidade"), b.get("status")] for b in open_bugs]
    parts += ["## Bugs abertos", "", table(["Bug", "Severidade", "Status"], rows)]

    return "\n".join(parts).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Builds docs/planejamento/BACKLOG.md")
    parser.add_argument("--check", action="store_true", help="fail if BACKLOG.md is out of date")
    args = parser.parse_args()

    content = build()
    if args.check:
        current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
        if current != content:
            print("BACKLOG.md is out of date: run `python3 tools/backlog.py` and commit it.", file=sys.stderr)
            return 1
        print("BACKLOG.md is up to date.")
        return 0

    OUTPUT.write_text(content, encoding="utf-8", newline="\n")
    print(f"BACKLOG.md updated ({OUTPUT.relative_to(ROOT).as_posix()}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
