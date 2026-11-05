---
tipo: historia
id: US-008
titulo: Config tipado do protótipo
status: backlog
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
- Módulos afetados: `src/shared/Config/Rede.luau`, `Movimento.luau`, `Camera.luau` e `Treino.luau`
- Remotes e validação no servidor: nenhum
- Dados persistidos: nenhum
- ADRs relevantes: [ADR-003](../../arquitetura/adr/ADR-003-luau-em-modo-strict.md)

## Tarefas
- [ ] Um módulo por assunto, congelado com `table.freeze`
- [ ] Comentário em cada valor: origem (aba de design ou "provisório do protótipo")
- [ ] Testar no Studio (cenários acima)
- [ ] Atualizar a documentação afetada

## Revisão / resultado
*Preenchido pelo dev ao terminar: o que foi feito, o que ficou de fora, como testar no Studio, PR.*
