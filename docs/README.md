# Documentação

O **design do jogo** fica no Claude Docs, onde é editado e comentado. A **documentação de engenharia** fica aqui, ao lado do código, onde o Claude Code lê e escreve.

## Design do jogo (Claude Docs)
[Projeto RPG · Design do Jogo](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ), com estas abas:

| Aba | O que tem |
| --- | --- |
| [Visão do Jogo](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ) | Pitch, público, loops, experiência desejada, monetização e o escopo aprovado do M1 |
| [Pilares de Design](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#55c20d98-b305) | Os cinco princípios que filtram toda ideia |
| [Sistemas](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#2bbf444e-c46a) | Índice dos sistemas, com o status de cada um |
| [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32) | GS, fama, maestria, raridade, tuning e ritmo |
| [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b) | Cores, derrubado, saque total, viagem |
| [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738) | Tipos, dungeon solo procedural, corrompidas |
| [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d) | Combate híbrido, energia e cooldown, esquiva e parry |
| [Armas e Armaduras](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#53e3dc55-5a40) | Armas iniciais, segunda mão e os três tipos de armadura |
| [Câmera e Mira](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f5514f82-709f) | Terceira pessoa, shift-lock e trava de alvo |
| [Movimentação](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#df937961-4ee9) | Andar, correr e pular no M1 |
| [Mundo e Terreno](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f460e959-73a7) | Regiões, terreno realista, tamanho pela travessia e otimização |
| [Facções](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#84a9d09f-f75b) | As três cidades, as facções e os brasões |
| [Revisão 03/11](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#08849064-3647) | Revisão da Visão, proposta de MVP e épicos candidatos |

## Engenharia (este repositório)

| Pasta | O que tem |
| --- | --- |
| [planejamento/](planejamento/) | [BACKLOG.md](planejamento/BACKLOG.md) (gerado), [ROADMAP.md](planejamento/ROADMAP.md), [Definições de Pronto](planejamento/DEFINICOES-DE-PRONTO.md), épicos e histórias |
| [arquitetura/](arquitetura/) | [Visão arquitetural](arquitetura/VISAO-ARQUITETURAL.md), [estrutura do repositório](arquitetura/ESTRUTURA-DO-REPOSITORIO.md), [convenções](arquitetura/CONVENCOES-DE-CODIGO.md) e ADRs |
| [processo/](processo/) | [Como trabalhar com o Claude](processo/COMO-TRABALHAR-COM-O-CLAUDE.md) |
| [referencias/](referencias/) | Anotações sobre jogos de referência ([Albion Online](referencias/albion-online.md)) |
| [conhecimento/](conhecimento/) | [Trilha de estudos](conhecimento/TRILHA-DE-ESTUDOS.md) de Roblox e Luau |
| [templates/](templates/) | Modelos de épico, história, ADR e bug |
| [dev/](dev/) | Bugs e playtests |
| [GLOSSARIO.md](GLOSSARIO.md) | Termos do jogo e de engenharia |

## Como atualizar o backlog
Mude as propriedades (`status`, `pontos`, `epico`…) no topo de cada arquivo e rode `python3 tools/backlog.py` (no Windows, `py tools/backlog.py`). O CI falha se o `BACKLOG.md` estiver desatualizado.
