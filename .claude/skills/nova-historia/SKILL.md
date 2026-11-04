---
name: nova-historia
description: Cria uma nova história de usuário no backlog a partir do template, com o próximo ID livre (US-NNN) e ligada a um épico. Use quando o Davi pedir para criar, escrever ou quebrar uma história.
argument-hint: título da história
---

# Criar uma história

1. **Próximo ID:** o maior `US-NNN` em `docs/planejamento/historias/` mais 1, com 3 dígitos.
2. **Pergunte ao Davi o que não estiver claro:** épico pai (`EP-NNN`), quem é o usuário, o que ele quer e por quê, prioridade (`must`, `should`, `could` ou `wont`) e critérios de aceite. Se ele não tiver os critérios, proponha no formato Dado / Quando / Então.
3. **Crie o arquivo:** copie `docs/templates/historia.md` para `docs/planejamento/historias/US-NNN-titulo-em-kebab-case.md` (sem acentos no nome) e preencha tudo, inclusive `titulo` e `epico` nas propriedades.
4. **Estime** em story points (1, 2, 3, 5 ou 8) e explique a estimativa. Se passar de 8, proponha quebrar.
5. **Deixe `status: backlog`.** Só o Davi move para `pronto`.
6. **Rode `python3 tools/backlog.py`** e mostre um resumo da história criada.
