---
tipo: historia
id: US-034
titulo: Inventário e fama no perfil, sem duplicar itens
status: revisao
prioridade: must
epico: EP-006
pontos: 3
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-034 · Inventário e fama no perfil, sem duplicar itens

## História
**Como** jogador,
**quero** que a mochila, o equipamento e a minha fama voltem quando eu entrar de novo,
**para que** o que conquistei continue comigo (Pilar 3: o progresso nunca se perde).

## Contexto
Critério do EP-006: sair e entrar mantém o inventário e a fama (o banco vem com a cidade, no EP-007). Regra 6 e ADR-006: cada item tem um `uid` único, e um perfil carregado nunca pode ter dois itens com o mesmo `uid`. Salvo pelo [ADR-005](../../arquitetura/adr/ADR-005-perfil-salvo-com-trava-de-sessao.md).

## Critérios de aceite
**Cenário 1: inventário volta**
- **Dado** um jogador com itens na mochila e equipados
- **Quando** ele sai e volta
- **Então** os mesmos itens, com os mesmos `uid`, estão nos mesmos lugares

**Cenário 2: fama volta**
- **Dado** um jogador com fama na Espada longa e em Espadas
- **Quando** ele sai e volta
- **Então** a especialização, a maestria e o GS são os mesmos

**Cenário 3: jogador novo**
- **Dado** um jogador sem perfil salvo
- **Quando** ele entra
- **Então** recebe o kit inicial equipado

**Cenário 4: uid repetido**
- **Dado** um perfil salvo com dois itens de mesmo `uid` (nunca deveria acontecer)
- **Quando** ele carrega
- **Então** só a primeira cópia fica, com um aviso no Output

**Cenário 5: item que saiu do catálogo**
- **Dado** um perfil com um item que não existe mais no `Config/Items`
- **Quando** ele carrega
- **Então** o item é descartado com um aviso, e o resto carrega

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados: `Services/InventoryService` (seção `inventory`, conferência dos itens salvos), `Services/MasteryService` (seção `mastery`)
- Remotes e validação no servidor: os mesmos de antes (`InventoryUpdate` e `ProgressUpdate` chegam depois do carregamento)
- Dados persistidos: `data.inventory = {{ bag, equipped }}` e `data.mastery = {{ items, lines }}`

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Inventário:** o kit inicial saiu do `PlayerAdded`. Agora é o padrão da seção `inventory` para quem não tem perfil.
- **Conferência dos itens salvos:** `uid` único, item que existe no catálogo, tier, raridade e durabilidade dentro dos limites. Um item salvo no slot errado volta para a mochila.
- **Fama:** a seção `mastery` aceita só totais positivos. Ao carregar, ela avisa o `StatsService`, e o GS já sai com os níveis salvos.
- **Antes de carregar:** o jogador ainda não tem inventário, então as habilidades dizem "sem arma" por um instante.

**Para o Davi testar no Studio** (com o place publicado e o acesso às APIs ligado, como na US-033):
1. Equipe um item do baú de teste, guarde outro na mochila e derrote bandidos até a maestria 3 ou mais.
2. Espere um minuto (salvamento automático), pare e dê Play de novo: os itens estão nos mesmos lugares (passe o mouse para ver), e a tela N mostra a mesma maestria.
3. Num perfil novo (outra conta, ou mude `STORE_NAME` no `Config/Profile`), o jogador recebe o kit inicial.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
