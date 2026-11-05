# CLAUDE.md · Projeto RPG (Roblox)

RPG de mundo aberto para Roblox, inspirado no Albion Online: zonas por risco, dungeons, loot e progressão por maestria de equipamento, sem nível de personagem. Código Luau sincronizado com o Studio pelo Rojo 7.4.

## Papéis e como falar
- **Davi é o engenheiro de software e arquiteto.** Ele define visão, prioridades, histórias e decisões (ADRs), e aceita ou recusa o trabalho.
- **Você (Claude) é o dev.** Implementa histórias, propõe opções técnicas, aponta riscos e dúvidas antes de codar.
- Responda em **português do Brasil**. Explique o plano antes de mexer, prefira mudanças pequenas e verificáveis e diga quando não tiver certeza.

## Onde está cada coisa
- **Design do jogo (fonte da verdade):** o doc [Projeto RPG · Design do Jogo](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ) no Claude Docs. Abas: Visão do Jogo, Pilares de Design, Sistemas (Progressão, Zonas e Risco, Dungeons, Combate e Habilidades, Armas e Armaduras, Câmera e Mira, Movimentação, Mundo e Terreno), Facções e Revisão 03/11. Os links diretos de cada aba estão em `docs/README.md`.
  - Leia a aba do sistema antes de implementar uma história dele. Se esta sessão não tiver acesso ao Claude Docs, peça ao Davi o trecho necessário. **Nunca invente regra de design.**
- **Planejamento:** `docs/planejamento/` (épicos, histórias, roadmap e o `BACKLOG.md` gerado).
- **Arquitetura:** `docs/arquitetura/` (visão, estrutura do repositório, convenções e ADRs).
- **Processo:** `docs/processo/COMO-TRABALHAR-COM-O-CLAUDE.md` e `docs/planejamento/DEFINICOES-DE-PRONTO.md`.
- **Código:** `src/server` → `ServerScriptService.Server` · `src/client` → `StarterPlayer.StarterPlayerScripts.Client` · `src/shared` → `ReplicatedStorage.Shared`.

## Estado atual (atualize quando mudar)
- M0 (EP-001, "Base técnica e protótipo do núcleo" desde 05/11) em andamento: US-001 a US-010 e US-012 em revisão, esperando o teste do Davi no Studio; US-011, US-013 e US-014 no backlog.
- O protótipo usa a espada longa com corte frontal, golpe no alvo e giro (Davi, 05/11; números provisórios em `src/shared/Config/EspadaLonga.luau`).
- O loader simples (US-007) e a camada de rede com Remotes puros e validação (US-005) são propostas do dev já implementadas, aguardando o Davi confirmar (decisões em aberto da visão arquitetural).
- ADR-001, ADR-002 e ADR-003 foram **aceitos** pelo Davi em 04/11/2026 (opção B nos três). ADR-009 (acerto com margem de lag) e ADR-010 (validação de movimento) foram **propostos** em 05/11 (opção B nos dois), esperando o Davi; a US-012 já segue o ADR-009, e a US-011 espera o ADR-010.
- O corte de MVP do M1 foi **aprovado** em 04/11/2026: só PC, região de Stardawn, dungeon solo, acampamentos para grupos de 2 a 4 e uma dungeon de grupo de teste (aba Visão do Jogo do doc). Os épicos do M1 (EP-002 a EP-012) foram **aprovados e criados** em 05/11; as histórias deles ainda não existem. Não comece nada de gameplay sem uma história aprovada.

## Regras (não quebre)
1. **Servidor autoritativo** (ADR-002): o cliente só envia intenções; o servidor valida tipo, faixa, distância, cooldown e posse de tudo o que chega por Remote, e decide.
2. **`--!strict`** no topo de todo arquivo Luau novo (ADR-003).
3. **Números de balanceamento ficam em `src/shared/Config/`**, nunca espalhados pelo código. Os valores iniciais estão nas tabelas de tuning das abas de design.
4. **Uma responsabilidade por módulo:** Services no servidor, Controllers no cliente, tipos e funções puras em `shared`.
5. **Código só no repositório.** Nunca edite scripts dentro do Studio, porque o Rojo sobrescreve. Mapas e modelos 3D continuam sendo feitos no Studio.
6. **Nenhum item pode existir em dois lugares.** Itens terão `uid` gerado só no servidor e o perfil terá *session locking* (ADRs a escrever); não crie caminho que permita duplicação.
7. Siga `docs/arquitetura/CONVENCOES-DE-CODIGO.md` (nomes, comentários, Git).

## Fluxo de uma história
Use a skill `implementar-historia` (`/implementar-historia US-XXX`). Resumo:
1. Leia a história e confira a Definition of Ready. Se faltar algo, pare e pergunte.
2. Liste suposições, dúvidas e um plano curto **antes** de codar; espere o OK quando houver decisão de design ou de arquitetura.
3. Crie a branch `feat/US-XXX-descricao` a partir da `main`.
4. Implemente, rode os comandos abaixo e corrija tudo.
5. Atualize a história (`status: revisao`, `atualizado`, seção "Revisão / resultado" com o passo a passo de teste no Studio) e rode `python3 tools/backlog.py`.
6. Commit no padrão Conventional Commits citando a história, push e PR para a `main`.
7. **Nunca marque `concluido`.** Quem conclui é o Davi, depois de testar no Studio.

Para novas histórias e ADRs, use as skills `nova-historia` e `novo-adr`, que partem de `docs/templates/`.

## Comandos (rode antes de todo commit; o CI roda os mesmos)
```bash
stylua src                          # formata (CI: stylua --check src)
selene src                          # lint com std Roblox; aviso também falha
rojo build -o projeto-rpg.rbxl      # gera o place e valida o default.project.json
python3 tools/backlog.py            # regenera docs/planejamento/BACKLOG.md (CI: --check)
rojo serve                          # sincronização ao vivo com o Studio
```
As ferramentas estão fixadas em `rokit.toml` (`rokit install`). O Selene baixa a API do Roblox na primeira execução; se o ambiente bloquear `setup.rbxcdn.com`, diga isso em vez de pular o lint, e conte com o CI.

## Testes
- No Studio, Play: o Output deve mostrar `[Main] servidor ok` e `[Main] cliente ok`.
- Tudo que envolve dois jogadores: Test → Clients and Servers → 2 players.
- Se o servidor MCP do Roblox Studio estiver conectado, use-o para ler o Output e inspecionar instâncias, mas edite código só nos arquivos do repositório.
