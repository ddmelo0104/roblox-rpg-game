---
tipo: historia
id: US-040
titulo: Saque total na Vermelha e kit de recomeço
status: revisao
prioridade: must
epico: EP-009
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-040 · Saque total na Vermelha e kit de recomeço

## História
**Como** jogador,
**quero** que morrer para outro jogador na Vermelha faça eu perder o que carrego, e voltar com um kit básico,
**para que** o risco da Vermelha valha a recompensa, sem nunca me deixar travado (Pilares 3 e 4).

## Contexto
Aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b), saque total:
- **Bolsa:** tudo o que se vestia e carregava cai numa bolsa no lugar da morte.
- **Destruição:** cada item tem 25% de chance de ser destruído.
- **Duração da bolsa:** 5 minutos, com 20 s de prioridade para quem finalizou.
- **Volta:** o jogador renasce na cidade mais próxima com o kit de recomeço (T1 Comum, grátis).

A bolsa é a mesma da US-026.

## Critérios de aceite
**Cenário 1: saque total**
- **Dado** um jogador finalizado na Vermelha
- **Quando** ele morre
- **Então** tudo o que vestia e carregava sai do inventário de uma vez; cada item tem 25% de chance de sumir, e o resto vai para uma bolsa no chão

**Cenário 2: prioridade**
- **Dado** a bolsa de um jogador finalizado
- **Quando** outro jogador tenta pegar nos primeiros 20 s
- **Então** só quem finalizou consegue; depois, qualquer um

**Cenário 3: kit de recomeço**
- **Dado** um jogador que perdeu tudo
- **Quando** ele renasce
- **Então** volta na cidade, com o kit inicial (T1 Comum) equipado

**Cenário 4: sem duplicar**
- **Dado** um item que foi para a bolsa
- **Quando** alguém o pega
- **Então** ele está só na mochila de quem pegou: o item saiu do inventário do morto no mesmo passo em que foi para a bolsa

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados: `KnockdownService` (saque total e renascer), `InventoryService.takeAll` e `giveRestartKit`, `LootBagService`, `ZoneService.returnPoint`, `Config/Knockdown.ITEM_DESTROY_CHANCE`
- Remotes e validação no servidor: os da US-039
- Dados persistidos: o inventário depois da perda, pelo perfil

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Tirar tudo:** o `InventoryService.takeAll` tira tudo numa chamada sem `yield`. O que sobra dos 25% vai para a bolsa, com prioridade para quem finalizou.
- **Morte e volta:** o jogador morre, renasce no ponto de retorno da cidade mais próxima e recebe o kit de recomeço nos slots vazios.
- **Moeda e banco:** a moeda carregada e o banco ainda não existem (cidade, EP-007).

**Para o Davi testar no Studio** (2 jogadores):
1. **Saque total:** o jogador 1 equipa itens do baú de teste e guarda outros na mochila. Os dois vão para a Vermelha, e o 2 derruba e finaliza o 1.
2. **Bolsa:** aparece no chão, e só o 2 consegue pegar nos primeiros 20 s. Em média, um quarto dos itens some.
3. **Volta:** o 1 renasce na cidade de teste (entre 250 e 400 studs à esquerda) com o kit inicial equipado e a mochila vazia.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
