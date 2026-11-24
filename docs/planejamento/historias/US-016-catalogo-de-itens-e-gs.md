---
tipo: historia
id: US-016
titulo: Catálogo de itens e contas de GS
status: revisao
prioridade: must
epico: EP-004
pontos: 3
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-016 · Catálogo de itens e contas de GS

## História
**Como** dev,
**quero** os itens do M1 descritos como dados e as contas de GS em funções puras,
**para que** inventário, equipamento, loot e progressão usem as mesmas regras.

## Contexto
Abas [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32) e [Armas e Armaduras](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#53e3dc55-5a40). História criada pelo dev, por delegação do Davi (23/11).
- **Armas:** espada longa, arco, besta e cajado de fogo (Davi, 04/11).
- **Armaduras:** leve, média e tanque, em elmo, peitoral e botas, mescláveis peça por peça (Davi, 04/11). Na aba Progressão, as linhas viram Tecido (leve), Couro (média) e Placa (tanque).
- **Tiers e raridades:** tiers T1 a T4 no M1 e 5 raridades, com o GS pela fórmula da aba Progressão.
- **Bônus de cada peça:** decididos pelo dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)).

## Critérios de aceite
**Cenário 1: o GS do item**
- **Dado** uma Espada longa T3 Rara, sem especialização e sem maestria
- **Quando** o servidor calcula o GS dela
- **Então** dá 340 (100 × 3 + 40)

**Cenário 2: o GS do personagem**
- **Dado** arma T2 Comum e elmo, peitoral e botas T1 Comuns
- **Quando** o GS do personagem é calculado
- **Então** dá 140 ((2 × 200 + 100 + 100 + 100) / 5)

**Cenário 3: os atributos**
- **Dado** um personagem com GS 300
- **Quando** os atributos são calculados
- **Então** o multiplicador é 1,16 (1 + 0,08 × 200 / 100)

## Notas técnicas (arquiteto → dev)
- Lado: compartilhado
- Módulos afetados: `src/shared/Config/Items.luau`, `src/shared/Config/Progression.luau` e `src/shared/Items.luau`
- Remotes e validação no servidor: nenhum
- Dados persistidos: nenhum (EP-006)
- ADRs relevantes: [ADR-006](../../arquitetura/adr/ADR-006-itens-como-registros-com-uid-do-servidor.md)

## Tarefas
- [x] Catálogo de armas e armaduras do M1
- [x] Fórmulas de GS do item, do personagem e dos atributos
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):** história e decisões do dev, por delegação do Davi.
- **`Config/Items`:**
  - As 4 armas e as 9 peças de armadura (leve, média e tanque, em elmo, peitoral e botas), com os nomes em português.
  - Os bônus de cada peça pelo tipo, os tiers T1 a T4, as 5 raridades, a mochila e o kit inicial.
- **`Config/Progression`:** os números de GS da aba Progressão.
- **`Shared.Items`:**
  - **GS do item:** um item quebrado vale 0.
  - **GS do personagem:** a arma conta 2 vezes, e um slot vazio vale 0.
  - **Multiplicador de atributos:** vale para dano e vida.
  - **Atributos do personagem:** somam os bônus de cada peça, com a resistência limitada a 75% e o cooldown a no mínimo 25% do original.

**Decisões do dev** (no [registro](../DECISOES-DELEGADAS.md)): os bônus por peça, os limites e os nomes das peças.

**Para o Davi testar no Studio:** os três cenários foram conferidos com a mesma conta (340, 140 e 1,16). No jogo, abra o inventário (I) e passe o mouse num item: o GS aparece no detalhe.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
