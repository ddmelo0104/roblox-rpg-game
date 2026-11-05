---
tipo: adr
id: ADR-009
titulo: Acerto das habilidades no servidor, com margem de lag
status: proposto
epicos: EP-001
criado: 2026-11-05
decidido_em:
substitui:
substituido_por:
---

# ADR-009 · Acerto das habilidades no servidor, com margem de lag

> [!NOTE]
> Status: **proposto** → aceito → (obsoleto | substituído).

## Contexto
Pelo [ADR-002](ADR-002-servidor-autoritativo.md), quem decide se uma habilidade acertou é o servidor. Só que o servidor e o cliente nunca veem o mundo no mesmo instante:
- a física do personagem é do cliente que o controla, e a posição dele chega ao servidor com atraso;
- o cliente vê os inimigos um pouco no passado.

Sem nenhum cuidado, um golpe que acertou na tela erra no servidor. A aba [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d) prevê uma tolerância de posição e tempo (`MARGEM_LAG`, "a definir no protótipo"). Ela também propõe que, no empate entre golpe e esquiva, ganhe quem defende.

O protótipo (US-012) só tem corpo a corpo: a espada longa com corte frontal, golpe no alvo travado e giro. Os projéteis da besta, do arco e do cajado chegam no EP-003.

## Opções consideradas
### Opção A: o servidor confere com as posições que ele tem, sem margem
- Prós: o mais simples e o mais difícil de trapacear.
- Contras: com lag, golpes que acertaram na tela erram, sobretudo contra quem se move. É a sensação de "mas eu acertei".

### Opção B: o servidor confere com as posições que ele tem, mais uma margem fixa
O cliente manda só a intenção: a habilidade, a direção e, no golpe no alvo, o alvo travado. O servidor confere cooldown, energia, alcance e linha de visão. Depois, calcula quem está na área com as posições dele, aumentando o alcance e a área em `MARGEM_LAG` studs.
- Prós:
  - Pouco código. As contas da área ficam num módulo puro em `shared`, e o cliente usa as mesmas contas para avisar antes de pedir e para desenhar o efeito na hora.
  - A margem é um número no Config, ajustável jogando.
  - No empate com a esquiva, vale o que o servidor processar primeiro, o que favorece quem defende, como a aba propõe.
- Contras:
  - Quem trapaceia ganha até `MARGEM_LAG` de alcance.
  - Com muito lag, contra alvos rápidos, ainda erra.
  - Pode não bastar para projéteis rápidos.

### Opção C: rebobinar o tempo (lag compensation)
O servidor guarda o histórico das posições (por exemplo, do último segundo) e confere o acerto onde o alvo estava quando o atacante apertou o botão, até um limite (por exemplo, 250 ms).
- Prós: o mais justo para quem ataca, e bom para mira e projéteis.
- Contras:
  - Bem mais código e memória.
  - Quem é atingido sente que levou o golpe já atrás da parede.
  - A hora do clique vem do cliente, ou de uma estimativa do ping, e um exploiter pode exagerar o atraso até o limite.
  - No Roblox, a posição do próprio atacante já chega atrasada ao servidor, o que complica a conta.

### Opção D: o cliente decide o acerto e o servidor só confere se é plausível
- Prós: resposta perfeita para quem ataca.
- Contras: contraria o ADR-002. Um exploiter manda "acertei" em tudo o que estiver dentro do plausível.

## Decisão
> [!IMPORTANT]
> **Proposta: opção B** no protótipo e no M1.
> - A margem começa em 1,5 stud (`Config/Combate.MARGEM_LAG`) e é ajustada no teste.
> - Reavaliar a opção C quando os projéteis do EP-003 entrarem, se os testes mostrarem erros demais.

## Consequências
- **Positivas:** todo acerto passa por um caminho só, no servidor, e o cliente prevê o efeito com as mesmas contas.
- **Negativas e trade-offs aceitos:** até `MARGEM_LAG` de alcance a mais para quem trapaceia. Quem tem lag alto erra mais contra alvos em movimento.
- **O que passa a ser obrigatório:**
  - O cliente nunca informa um acerto, só a intenção. O alvo travado também é uma intenção: o servidor confere tag, vida, alcance e linha de visão.
  - Toda habilidade calcula o acerto com as funções de `Shared.Habilidades` e com a margem do Config.
  - O servidor confere a linha de visão. Só o cenário bloqueia, não os personagens.

## Referências
- Aba [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d): `MARGEM_LAG` e o empate entre golpe e esquiva.
- [Network ownership](https://create.roblox.com/docs/physics/network-ownership): a física do personagem é do cliente que o controla.
- [Workspace:GetServerTimeNow](https://create.roblox.com/docs/reference/engine/classes/Workspace#GetServerTimeNow): o relógio do servidor, usado nos cooldowns dos dois lados.
