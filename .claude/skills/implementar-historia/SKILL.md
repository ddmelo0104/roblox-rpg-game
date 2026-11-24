---
name: implementar-historia
description: Implementa uma história de usuário (US-XXX) do backlog seguindo o processo do projeto. Confere a Definition of Ready, levanta dúvidas antes de codar, cria a branch, implementa, roda os checks, atualiza a história e o backlog e abre o PR. Use quando o Davi pedir para implementar, fazer ou começar uma história.
argument-hint: US-XXX
---

# Implementar uma história

O argumento é o ID da história (ex.: `US-005`). Se ele não vier, pergunte qual é.

1. **Leia a história** em `docs/planejamento/historias/` (o arquivo que começa com o ID). Leia também o épico em `docs/planejamento/epicos/`, os ADRs citados e a aba do doc de design do sistema envolvido (links em `docs/README.md`).
2. **Confira a Definition of Ready** em `docs/planejamento/DEFINICOES-DE-PRONTO.md`. Se a história não estiver em `pronto`, ou faltar critério de aceite, estimativa ou decisão técnica, pare e diga ao Davi o que falta.
3. **Antes de codar, responda no chat:** suposições, dúvidas, um plano curto (arquivos que vai criar ou mudar, e por quê) e os riscos. Se alguma dúvida for de design ou de arquitetura, espere a resposta.
4. **Crie a branch:** `git switch main`, `git pull` e `git switch -c feat/US-XXX-descricao-curta`.
5. **Implemente** seguindo o `CLAUDE.md` e `docs/arquitetura/CONVENCOES-DE-CODIGO.md`: `--!strict`, servidor autoritativo, números em `src/shared/Config/`.
6. **Rode e corrija até passar:** `stylua src`, `selene src` e `rojo build -o roblox-rpg-game.rbxl`.
7. **Atualize a história:** `status: revisao`, `atualizado: <hoje>`, marque as tarefas feitas e preencha "Revisão / resultado" com o que foi feito, o que ficou de fora e **o passo a passo para o Davi testar no Studio**, cenário por cenário.
8. **Regenere o backlog:** `python3 tools/backlog.py`.
9. **Faça commit e abra o PR:** Conventional Commits citando a história (ex.: `feat(rede): validar RequestPing no servidor (US-005)`), push da branch e PR para a `main` com o template preenchido.
10. **Não marque `concluido`.** Termine dizendo ao Davi como testar e o que olhar no diff.
