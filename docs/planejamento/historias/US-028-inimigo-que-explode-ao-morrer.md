---
tipo: historia
id: US-028
titulo: Inimigo que explode ao morrer
status: revisao
prioridade: must
epico: EP-008
pontos: 2
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-028 · Inimigo que explode ao morrer

## História
**Como** jogador,
**quero** inimigos com efeito ao morrer,
**para que** eu pense em onde lutar e as lutas não se repitam (Pilar 2).

## Contexto
Aba [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738): "inimigos com efeito ao morrer, como os Diabretes (veneno, magma, explosão)", que pedem estratégia de posicionamento. Decisão do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)): o bandido com pólvora explode ao morrer. Um círculo cresce por 1,2 s, e a explosão tem raio de 10 studs e dá 25 de dano (×1,04 no T1). Só a esquiva evita, e a explosão só acerta jogadores.

## Critérios de aceite
**Cenário 1: aviso**
- **Dado** um bandido com pólvora derrotado
- **Quando** ele cai
- **Então** um círculo laranja cresce no chão por 1,2 s, mostrando a área

**Cenário 2: explosão**
- **Dado** um jogador dentro do círculo
- **Quando** o círculo termina
- **Então** ele leva o dano da explosão, a menos que esteja esquivando

**Cenário 3: fora do círculo**
- **Dado** um jogador fora do círculo
- **Quando** a explosão acontece
- **Então** ele não leva dano

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados: `deathBlast` nos tipos do `Config/Enemies`, `EnemyBrain.blast`, `EnemyService`
- Remotes e validação no servidor: nenhum; o dano passa pelo `DefenseService.receiveHit` como golpe à distância
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):** qualquer tipo pode ter `deathBlast` (raio, dano e atraso). O dano escala com o tier e o elite, como o do ataque. O círculo e o clarão são peças criadas pelo servidor, que não bloqueiam a linha de visão.

**Para o Davi testar no Studio:**
1. **Aviso e explosão:** vá ao terceiro grupo da área de teste (160 studs à esquerda) e derrote o bandido com pólvora de perto. O círculo cresce: fique dentro e veja o dano.
2. **Esquivar:** repita (ele renasce em 45 s) e esquive (F) no fim do círculo: "Esquivou" aparece e não há dano.
3. **Sair:** repita e saia do círculo antes do fim: sem dano.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
