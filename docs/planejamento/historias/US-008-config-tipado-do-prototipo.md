---
tipo: historia
id: US-008
titulo: Config tipado do protótipo
status: revisao
prioridade: must
epico: EP-001
pontos: 1
sprint:
criado: 2026-11-05
atualizado: 2026-11-05
concluido_em:
---

# US-008 · Config tipado do protótipo

## História
**Como** arquiteto,
**quero** os números do protótipo (rede, movimento, câmera e boneco de treino) em módulos de `src/shared/Config/`,
**para que** eu ajuste o "sentir" do jogo mudando um arquivo só.

## Contexto
Regra 3 do `CLAUDE.md`. As tabelas de tuning das abas Movimentação e Câmera e Mira dizem "a definir no protótipo": os valores aqui são os **iniciais do protótipo**, marcados como provisórios, e o protótipo serve para acertá-los. Os números de combate entram com a US-012.

## Critérios de aceite
**Cenário 1: valores num lugar só**
- **Dado** o código das histórias do EP-001
- **Quando** eu procuro um número de balanceamento ou uma tecla do protótipo
- **Então** ele está em `src/shared/Config/`, com um comentário dizendo de onde veio

**Cenário 2: valores protegidos**
- **Dado** um script que tenta mudar um valor do Config durante o jogo
- **Quando** ele roda
- **Então** dá erro, porque a tabela é congelada

## Notas técnicas (arquiteto → dev)
- Lado: compartilhado
- Módulos afetados: `src/shared/Config/Network.luau`, `Movement.luau`, `Camera.luau` e `Training.luau`
- Remotes e validação no servidor: nenhum
- Dados persistidos: nenhum
- ADRs relevantes: [ADR-003](../../arquitetura/adr/ADR-003-luau-em-modo-strict.md)

## Tarefas
- [x] Um módulo por assunto, congelado com `table.freeze`
- [x] Comentário em cada valor: origem (aba de design ou "provisório do protótipo")
- [ ] Testar no Studio (cenários acima)
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-05):** `src/shared/Config/` com `Network`, `Movement`, `Camera` e `Training`. Cada módulo é congelado com `table.freeze`, e cada valor tem um comentário dizendo de onde veio. Os valores de movimento e de câmera são **provisórios do protótipo**, porque as abas dizem "a definir no protótipo":

| Valor | Inicial | Arquivo |
| --- | --- | --- |
| Velocidade de andar / correr | 16 / 24 studs/s | `Movement` |
| Altura do pulo | 7,2 studs | `Movement` |
| Zoom mínimo / máximo | 6 / 22 studs | `Camera` |
| Alcance da trava / ângulo para travar | 60 studs / 45° | `Camera` |
| Tempo sem visão até soltar a trava | 1,5 s | `Camera` |
| Teclas | Shift corre, Ctrl modo combate, T ou botão do meio trava, Tab troca | `Movement` e `Camera` |
| Vida do boneco / tempo para voltar | 1000 / 5 s | `Training` |

**Para o Davi testar no Studio:**
1. **Cenário 1:** abra os quatro arquivos e confira que os números das US-005, US-009 e US-010 estão só ali.
2. **Cenário 2:** dê Play e rode na barra de comandos (servidor): `require(game.ReplicatedStorage.Shared.Config.Movement).SPRINT_SPEED = 1`. Tem que dar erro de tabela somente leitura.
3. Para ajustar o "sentir": mude um valor no arquivo, salve (o Rojo sincroniza) e dê Play de novo.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
