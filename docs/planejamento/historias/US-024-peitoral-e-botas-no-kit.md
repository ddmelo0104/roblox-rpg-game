---
tipo: historia
id: US-024
titulo: Habilidade do peitoral e esquiva pelas botas
status: revisao
prioridade: must
epico: EP-003
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-024 · Habilidade do peitoral e esquiva pelas botas

## História
**Como** jogador,
**quero** que o peitoral me dê uma habilidade e que as botas mudem a minha esquiva,
**para que** misturar armaduras mude o meu kit (Pilar 5).

## Contexto
Aba [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d): a habilidade do peitoral, e "a esquiva é definida pelas botas" (Davi, 04/11). Os tipos seguem o Davi (04/11): leve favorece dano e cooldown, média é equilibrada e tanque aguenta mais. As habilidades e os números foram decididos pelo dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Peitoral leve:** Foco (devolve 30 de energia).
- **Peitoral médio:** Fôlego (cura 20% da vida).
- **Peitoral tanque:** Fortaleza (+40% de resistência por 4 s).
- **Botas:** a leve avança 14 studs (1,6 s de cooldown), a média 12 (2 s) e a tanque 8, com mais invulnerabilidade (2,5 s).

## Critérios de aceite
**Cenário 1: peitoral**
- **Dado** uma Jaqueta de couro equipada
- **Quando** o jogador aperta C
- **Então** ele cura 20% da vida, "Fôlego" aparece em cima dele e o cooldown começa

**Cenário 2: trocar o peitoral**
- **Dado** o jogador equipa uma Armadura de placa
- **Quando** o HUD atualiza
- **Então** o quadro C vira Fortaleza

**Cenário 3: botas**
- **Dado** Botas de placa equipadas
- **Quando** o jogador esquiva
- **Então** o avanço é curto e o cooldown, maior

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `src/shared/Config/Armor.luau`, `Shared.Items` (`chestAbilityOf`, `dodgeOf`), `CombatService`, `DefenseService`, `EnergyService.restore`, `StatsService.addResistance`, `DefenseController`
- Remotes e validação no servidor: `RequestAbility` com o id do peitoral vestido; a esquiva usa as botas vestidas
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Habilidade do peitoral (C):** passa pelo mesmo pedido das habilidades. O servidor confere se ela é do peitoral vestido, além do cooldown (com a redução do equipamento) e da energia, e aplica o efeito: energia, cura ou resistência temporária. A resistência temporária soma com a do equipamento, até 75%.
- **Esquiva pelas botas:** a distância, a invulnerabilidade e o cooldown vêm das botas vestidas (`Config/Armor.BOOTS_DODGES`). Sem botas, vale a média. O cliente usa a mesma tabela para o avanço e para o HUD.

**Para o Davi testar no Studio:**
1. **Peitoral:** com o kit inicial (couro), perca vida no boneco que ataca e aperte C. "Fôlego" aparece, e a vida sobe.
2. **Trocar o peitoral:** pegue peitorais no baú e equipe. O quadro C muda para Foco ou Fortaleza.
3. **Botas:** com botas de placa, a esquiva (F) avança menos e demora mais para voltar. Com botas de tecido, avança mais.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
