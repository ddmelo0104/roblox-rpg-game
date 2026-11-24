---
tipo: historia
id: US-045
titulo: Quest de tutorial na zona Azul
status: revisao
prioridade: must
epico: EP-011
pontos: 3
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-045 · Quest de tutorial na zona Azul

## História
**Como** jogador novo,
**quero** uma quest curta que me ensine o básico ao nascer,
**para que** eu saiba jogar sem precisar perguntar (critério do M1).

## Contexto
Aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b): o jogador nasce na zona Azul, faz uma quest de tutorial simples e segue para a cidade; no M1, só essa quest (Davi, 05/11). O conteúdo era pergunta aberta da aba e foi decidido pelo dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)). São 5 passos:
1. Travar e acertar um boneco de treino.
2. Esquivar ou aparar um golpe do boneco que ataca.
3. Derrotar 3 bandidos.
4. Equipar um item.
5. Chegar à cidade.

A recompensa é uma versão Rara da arma que o jogador usa.

## Critérios de aceite
**Cenário 1: passos**
- **Dado** um jogador novo
- **Quando** ele entra
- **Então** o canto direito mostra "Tutorial 1/5 · Trave um boneco de treino (T) e acerte-o com Q, E ou R"

**Cenário 2: avançar**
- **Dado** o passo de derrotar 3 bandidos
- **Quando** o jogador derrota um
- **Então** o texto mostra "(1/3)"; no terceiro, passa para o próximo passo

**Cenário 3: concluir**
- **Dado** o último passo
- **Quando** o jogador entra na cidade
- **Então** aparece "Tutorial concluído! Você ganhou: …" com uma arma Rara do tipo que ele usa, na mochila

**Cenário 4: salvo**
- **Dado** um jogador no passo 3
- **Quando** ele sai e volta
- **Então** continua no passo 3; quem concluiu não vê o tutorial de novo

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `Services/TutorialService` (novo, seção `tutorial` do perfil), `Config/Tutorial` (passos), ganchos novos: `DefenseService.onDefended`, `InventoryService.onEquipped`, `ZoneService.onZoneChanged`, atributo `TrainingDummy` nos bonecos, `TutorialController` (novo)
- Remotes e validação no servidor: `TutorialUpdate`: aviso do servidor; o progresso só anda com eventos que o servidor viu
- Dados persistidos: `data.tutorial = {{ step, count }}` no perfil

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Passos:** ficam no `Config/Tutorial`, cada um esperando um evento do servidor.
- **Eventos:**
  - um golpe num boneco de treino;
  - uma esquiva ou um parry;
  - um abate com crédito;
  - equipar um item;
  - entrar numa zona do tipo pedido.
- **Progresso:** é uma seção do perfil, então quem sai continua de onde parou.

**Para o Davi testar no Studio:**
1. **Os 5 passos:** dê Play e siga o texto no canto direito: acerte um boneco, defenda um golpe do boneco que ataca, derrote 3 bandidos, equipe um item do baú (G e depois I) e ande até a cidade (250 studs à esquerda).
2. **Recompensa:** ao chegar na cidade, aparece a mensagem com a arma Rara, e ela está na mochila.
3. **Salvo:** com o perfil salvo (US-033), saia no meio e volte: o tutorial continua do mesmo passo.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
