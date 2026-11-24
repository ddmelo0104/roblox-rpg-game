---
tipo: epico
id: EP-002
titulo: Personagem, câmera e controles (PC)
status: backlog
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-05
---

# EP-002 · Personagem, câmera e controles (PC)

> O personagem anda, corre e pula pelo mundo, com câmera em terceira pessoa, shift-lock e trava de alvo, tudo no PC.

## Objetivo
Dar ao jogador o controle básico do personagem e da câmera em que todo o resto do M1 se apoia: explorar, mirar e lutar.

## Contexto
Pilares 2 (combate divertido) e 4 (zonas e áreas). Regras nas abas [Câmera e Mira](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f5514f82-709f) e [Movimentação](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#df937961-4ee9). Os números saem do protótipo do EP-001.

## Escopo
**Dentro**
- Andar, correr e pular, com os valores em `src/shared/Config/`.
- Validação de movimento no servidor, contra speed hack e teleporte (ADR-010, a escrever).
- Câmera em terceira pessoa com zoom mínimo e máximo.
- Shift-lock e trava de alvo: travar, trocar e soltar o alvo; as habilidades de área continuam acertando todos.
- Controles de PC (teclado e mouse).

**Fora**
- Controles e UI de celular (depois do M1).
- Esquiva, que vem das botas (EP-003), e montaria (depois do M1).

## Critérios de conclusão
- [ ] Com 2 jogadores (Test → 2 players), andar, correr e pular funcionam, e o servidor corrige quem passa da velocidade permitida
- [ ] A câmera trava num alvo, troca de alvo e solta quando o alvo morre ou sai do alcance
- [ ] Todos os valores ficam em `src/shared/Config/`

## Métricas de sucesso
Num playtest, quem joga pela primeira vez anda, corre e trava num alvo sem explicação.

## Dependências
- Depende de: EP-001 (protótipo do núcleo) e ADR-010 (a escrever)
- Bloqueia: EP-003 e EP-007

## Riscos
> [!WARNING]
> **A validação de movimento punir quem está com lag.** Probabilidade média, impacto alto. Mitigação: margem de tolerância em Config, calibrada com 2 jogadores e lag simulado no Studio.

## Perguntas em aberto
As perguntas de câmera e de movimento estão nas abas [Câmera e Mira](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f5514f82-709f) e [Movimentação](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#df937961-4ee9).

## Histórias
O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
