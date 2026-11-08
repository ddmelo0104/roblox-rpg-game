---
tipo: adr
id: ADR-010
titulo: Validação de movimento no servidor
status: proposto
epicos: EP-001
criado: 2026-11-05
decidido_em:
substitui:
substituido_por:
---

# ADR-010 · Validação de movimento no servidor

> [!NOTE]
> Status: **proposto** → aceito → (obsoleto | substituído).

## Contexto
No Roblox, a física do personagem é do cliente que o controla (*network ownership*), e por isso andar não tem atraso. O lado ruim é que um exploiter consegue mudar a própria velocidade, se teleportar ou voar, e o servidor aceita.

Na US-010, o servidor já decide a velocidade (`MovementService.allowedSpeed`), mas o cliente pode ignorá-la. Num jogo com saque total, fugir ou alcançar alguém com speed hack quebra o jogo ([ADR-002](ADR-002-servidor-autoritativo.md)). A aba [Movimentação](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#df937961-4ee9) pede que a correção tenha margem, para não punir quem está com lag.

O Roblox tem um modo próprio de autoridade do servidor (*Server Authority*, com `Workspace.AuthorityMode = Server`): o servidor simula, e o cliente prevê e corrige (*rollback*). Ele saiu em beta no Studio e depois foi anunciado como liberado, mas liga junto outras mudanças e ainda tem problemas conhecidos (ver Referências).

## Opções consideradas
### Opção A: não validar
- Prós: nenhum código.
- Contras: speed hack e teleporte livres. Inaceitável pelo ADR-002.

### Opção B: conferência própria no servidor, com margem e puxão de volta
A cada intervalo (proposta: 0,5 s), o servidor compara o deslocamento horizontal de cada personagem, desde a última posição válida, com o máximo permitido: velocidade permitida × tempo × (1 + margem), mais uma folga fixa.
- Se passar, o servidor devolve o personagem para a última posição válida e registra um aviso.
- Teleportes feitos pelo próprio servidor (renascer, portais) avisam a validação, que aceita a nova posição.
- Queda livre não conta. Voo e atravessar paredes ficam para depois.

Prós e contras:
- Prós:
  - É o caminho comum na plataforma, com pouco código e barato: uma conta por jogador por intervalo.
  - Funciona com o código atual do protótipo, e os números ficam no Config.
- Contras:
  - Trapaça pequena, dentro da margem, passa.
  - Lag forte pode causar puxões, e a margem e o intervalo reduzem isso.
  - Esta primeira versão não pega voo nem atravessar paredes.

### Opção C: o Server Authority do Roblox
- Prós: o servidor simula o movimento, com previsão no cliente. Resolve speed hack e teleporte na raiz, com menos código nosso.
- Contras:
  - É novo, e o status está pouco claro: o anúncio de "Full Release" ainda fala em beta.
  - Muda outras partes do jogo: liga a replicação nova, o sistema de input novo nos scripts do jogador e os sinais adiados (*deferred*).
  - O modo combate do protótipo vira o personagem pelo `CFrame` no cliente, o que teria de ser revisto.
  - Há relatos de problemas de rollback em lutas.

### Opção D: movimento simulado pelo nosso servidor
- Prós: à prova de speed hack.
- Contras: é preciso tirar a física do cliente e escrever a previsão e a correção à mão. É muito trabalho, e o atraso aparece ao andar.

## Decisão
> [!IMPORTANT]
> **Proposta: opção B** agora (US-011), com os números em `Config/Movement`.
> - Em paralelo, uma spike curta para testar a opção C no protótipo antes do EP-002.
> - Se a opção C for boa, um novo ADR substitui este.

## Consequências
- **Positivas:** speed hack e teleporte deixam de funcionar, e o movimento continua sem atraso.
- **Negativas e trade-offs aceitos:**
  - Trapaça pequena, dentro da margem, passa.
  - Voo e atravessar paredes ficam para uma segunda versão.
  - Com lag muito alto, pode haver puxões raros.
- **O que passa a ser obrigatório:**
  - Todo teleporte feito pelo servidor passa pela função da validação, para não virar falso positivo.
  - Toda mudança de velocidade decidida pelo servidor (corrida, lentidão, investida) entra em `MovementService.allowedSpeed`.

## Referências
- Aba [Movimentação](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#df937961-4ee9): correção com margem para quem está com lag.
- [Network ownership](https://create.roblox.com/docs/physics/network-ownership): a física do personagem é do cliente que o controla.
- [Studio Beta: Server Authority](https://devforum.roblox.com/t/studio-beta-build-fair-responsive-games-with-server-authority/4139157), [Full Release: Server Authority](https://devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993) e [Roblox Newsroom (07/2026)](https://about.roblox.com/newsroom/2026/07/creating-responsive-cheat-resistant-games-roblox-server-authority): como ligar e o que muda.
- [Relato da comunidade sobre o beta](https://devforum.roblox.com/t/server-authority-client-beta-was-a-damn-nightmare-heres-some-advice/4712758?page=2): problemas de rollback e de atraso de input.
