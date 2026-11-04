#!/usr/bin/env python3
"""
backlog.py: gera docs/planejamento/BACKLOG.md a partir das propriedades (frontmatter)
dos épicos, histórias, ADRs e bugs em docs/. Substitui os painéis do antigo vault.

Uso:
    python3 tools/backlog.py           # regenera o arquivo
    python3 tools/backlog.py --check   # só confere se está atualizado (usado no CI)

No Windows, troque `python3` por `py`. Só usa a biblioteca padrão (Python 3.8+).
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
DOCS = RAIZ / "docs"
PLANEJAMENTO = DOCS / "planejamento"
SAIDA = PLANEJAMENTO / "BACKLOG.md"

ORDEM_PRIORIDADE = {"must": 0, "should": 1, "could": 2, "wont": 3}
SECOES_HISTORIAS = [
    ("Em andamento e em revisão", {"em-andamento", "revisao"}),
    ("Prontas para começar", {"pronto"}),
    ("Backlog", {"backlog", "ideia"}),
    ("Concluídas", {"concluido"}),
]


def ler_frontmatter(caminho: Path) -> dict:
    """Lê o bloco `---` do topo do arquivo como pares chave: valor (formato simples, sem listas aninhadas)."""
    texto = caminho.read_text(encoding="utf-8")
    dados: dict = {"_arquivo": caminho}
    if texto.startswith("---"):
        fim = texto.find("\n---", 3)
        if fim != -1:
            for linha in texto[3:fim].splitlines():
                if ":" not in linha or linha.lstrip().startswith("#"):
                    continue
                chave, _, valor = linha.partition(":")
                dados[chave.strip()] = valor.strip().strip('"').strip("'")
    if not dados.get("titulo"):
        titulo = re.search(r"^# (.+)$", texto, flags=re.MULTILINE)
        if titulo:
            dados["titulo"] = titulo.group(1).split("·", 1)[-1].strip()
    return dados


def carregar(pasta: Path, prefixo: str) -> list:
    """Todos os arquivos `PREFIXO-*.md` da pasta que têm `id`, ordenados pelo id."""
    if not pasta.exists():
        return []
    itens = [ler_frontmatter(p) for p in sorted(pasta.glob(f"{prefixo}-*.md"))]
    return sorted((i for i in itens if i.get("id")), key=lambda i: i["id"])


def celula(valor) -> str:
    """Texto seguro para uma célula de tabela Markdown."""
    return str(valor).replace("|", "\\|") if valor not in (None, "") else "—"


def link(item: dict) -> str:
    """Link relativo ao BACKLOG.md, no formato `[ID · Título](caminho)`."""
    destino = Path(os.path.relpath(item["_arquivo"], SAIDA.parent)).as_posix()
    return f"[{item['id']} · {celula(item.get('titulo', ''))}]({destino})"


def pontos(item: dict) -> int:
    try:
        return int(item.get("pontos") or 0)
    except ValueError:
        return 0


def tabela(cabecalho: list, linhas: list) -> str:
    if not linhas:
        return "_Nada por aqui._\n"
    saida = ["| " + " | ".join(cabecalho) + " |", "|" + " --- |" * len(cabecalho)]
    saida += ["| " + " | ".join(celula(c) for c in linha) + " |" for linha in linhas]
    return "\n".join(saida) + "\n"


def gerar() -> str:
    epicos = carregar(PLANEJAMENTO / "epicos", "EP")
    historias = carregar(PLANEJAMENTO / "historias", "US")
    adrs = carregar(DOCS / "arquitetura" / "adr", "ADR")
    bugs = carregar(DOCS / "dev" / "bugs", "BUG")

    partes = [
        "<!-- Gerado por tools/backlog.py. Não edite à mão: mude os arquivos e rode o script. -->",
        "",
        "# Backlog",
        "",
        "Visão geral do planejamento, montada a partir das propriedades de cada arquivo em `docs/`.",
        "Fluxo das histórias: `backlog` → `pronto` → `em-andamento` → `revisao` → `concluido` (ou `cancelado`).",
        "Regras de cada passagem em [Definições de Pronto](DEFINICOES-DE-PRONTO.md).",
        "",
    ]

    linhas = []
    for epico in epicos:
        dele = [h for h in historias if h.get("epico") == epico["id"]]
        feitas = [h for h in dele if h.get("status") == "concluido"]
        progresso = (
            f"{len(feitas)}/{len(dele)} histórias · {sum(map(pontos, feitas))}/{sum(map(pontos, dele))} pts"
            if dele
            else "sem histórias"
        )
        linhas.append([link(epico), epico.get("status"), epico.get("prioridade"), epico.get("marco"), progresso])
    partes += ["## Épicos", "", tabela(["Épico", "Status", "Prioridade", "Marco", "Progresso"], linhas)]

    for titulo, estados in SECOES_HISTORIAS:
        selecionadas = [h for h in historias if h.get("status") in estados]
        selecionadas.sort(key=lambda h: (ORDEM_PRIORIDADE.get(h.get("prioridade", ""), 9), h["id"]))
        linhas = [
            [link(h), h.get("status"), h.get("epico"), h.get("prioridade"), pontos(h) or "?"] for h in selecionadas
        ]
        partes += [f"## {titulo}", "", tabela(["História", "Status", "Épico", "Prioridade", "Pts"], linhas)]

    incompletas = [
        h
        for h in historias
        if h.get("status") not in {"concluido", "cancelado"} and (not h.get("epico") or not pontos(h))
    ]
    if incompletas:
        partes += ["## Histórias sem épico ou sem estimativa", "", *(f"- {link(h)}" for h in incompletas), ""]

    partes += ["## Decisões (ADRs)", "", tabela(["ADR", "Status"], [[link(a), a.get("status")] for a in adrs])]

    abertos = [b for b in bugs if b.get("status") not in {"resolvido", "fechado"}]
    linhas = [[link(b), b.get("severidade"), b.get("status")] for b in abertos]
    partes += ["## Bugs abertos", "", tabela(["Bug", "Severidade", "Status"], linhas)]

    return "\n".join(partes).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Gera docs/planejamento/BACKLOG.md")
    parser.add_argument("--check", action="store_true", help="falha se o BACKLOG.md estiver desatualizado")
    args = parser.parse_args()

    conteudo = gerar()
    if args.check:
        atual = SAIDA.read_text(encoding="utf-8") if SAIDA.exists() else ""
        if atual != conteudo:
            print("BACKLOG.md desatualizado: rode `python3 tools/backlog.py` e faça commit.", file=sys.stderr)
            return 1
        print("BACKLOG.md em dia.")
        return 0

    SAIDA.write_text(conteudo, encoding="utf-8", newline="\n")
    print(f"BACKLOG.md atualizado ({SAIDA.relative_to(RAIZ).as_posix()}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
