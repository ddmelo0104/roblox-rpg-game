---
tipo: historia
id: US-021
titulo: O kit de habilidades vem da arma equipada
status: revisao
prioridade: must
epico: EP-003
pontos: 3
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-021 · O kit de habilidades vem da arma equipada

## História
**Como** jogador,
**quero** que as habilidades mudem quando eu troco de arma,
**para que** a arma defina o meu estilo (Pilar 5).

## Contexto
Aba [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d): o kit vem do equipamento, com 3 habilidades da arma. História criada pelo dev por delegação (23/11).

## Critérios de aceite
**Cenário 1: trocar de arma**
- **Dado** a Espada longa equipada, com Q, E e R da espada no HUD
- **Quando** o jogador equipa um Arco
- **Então** o HUD passa a mostrar as habilidades do arco, e Q, E e R usam o arco

**Cenário 2: habilidade de outra arma**
- **Dado** o Arco equipado
- **Quando** um cliente pede uma habilidade da espada
- **Então** o servidor recusa ("NoWeapon")

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `src/shared/Weapons.luau` (registro dos kits), `CombatService`, `CombatController`, `CombatHudController`
- Remotes e validação no servidor: `RequestAbility`: o id precisa ser do kit da arma vestida
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Kits:** cada arma tem um Config com `BASIC_ATTACK` e `ABILITIES` (`Longsword`, `Bow`, `Crossbow`, `FireStaff`), e `Shared.Weapons` junta os quatro. O servidor confere todos ao iniciar.
- **Servidor:** só aceita habilidades da arma que o jogador veste; qualquer outra é recusada com "NoWeapon".
- **HUD:** os quadros mudam quando a arma, o peitoral ou as botas mudam.

**Para o Davi testar no Studio:** abra o baú de teste até sair um Arco, uma Besta ou um Cajado de fogo, e equipe pelo inventário (I). Os quadros Q, E e R do HUD trocam para as habilidades da nova arma.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
