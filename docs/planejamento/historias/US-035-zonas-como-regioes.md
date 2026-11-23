---
tipo: historia
id: US-035
titulo: Zonas como regiões do mundo, com a zona atual no HUD
status: revisao
prioridade: must
epico: EP-007
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-035 · Zonas como regiões do mundo, com a zona atual no HUD

## História
**Como** jogador,
**quero** saber sempre em que zona estou, com a cor, o tier e o GS recomendado,
**para que** o risco seja uma escolha minha (princípio 1 da aba Zonas e Risco).

## Contexto
Aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b):
- No M1, Azul (tutorial) ↔ Cidade ↔ Amarela T2 ↔ Vermelha T3, num place só.
- As regras da zona são dados, e o GS recomendado é `100 × tier + 50`.

A topologia é a do [ADR-004](../../arquitetura/adr/ADR-004-um-place-so-no-m1.md) (proposto pelo dev). Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Traçado de teste:** num place sem regiões, as zonas aparecem em linha à esquerda do spawn.
- **Herança:** pontos de spawn sem `Tier` nem `Zone` herdam os da zona onde estão.

## Critérios de aceite
**Cenário 1: zona no HUD**
- **Dado** um jogador na zona Azul de teste
- **Quando** ele joga
- **Então** o topo da tela mostra "Campos de Stardawn · Zona Azul T1 · GS recomendado 150", em azul

**Cenário 2: trocar de zona**
- **Dado** o jogador fora de combate
- **Quando** ele anda para a cidade de teste (250 studs à esquerda)
- **Então** o topo muda para "Stardawn · Cidade", e uma faixa diz "Cidade: Segura: ninguém toma dano aqui."

**Cenário 3: regiões do Studio**
- **Dado** uma parte com a tag `Zone` e os atributos `Zone = Yellow`, `Tier = 2` e `ZoneName`
- **Quando** o jogador entra nela
- **Então** o HUD mostra a zona e o tier dela; a parte fica invisível e sem colisão

**Cenário 4: inimigos herdam a zona**
- **Dado** um ponto de spawn sem `Tier` nem `Zone` dentro da zona Vermelha T3
- **Quando** o inimigo nasce
- **Então** ele tem a força do T3, e o loot e a fama usam a sorte e o multiplicador da Vermelha

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `Services/ZoneService` (novo), `Shared.Zones` (novo), `Config/Zones` (tipos de zona e traçado de teste), `EnemyService` (herança), `Config/Enemies` (grupos de teste na Amarela e na Vermelha), `ZoneController` (novo)
- Remotes e validação no servidor: nenhum Remote novo: o servidor publica a zona em atributos do jogador
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Regiões:** o `ZoneService` lê as partes com a tag `Zone` no `Init` (vale a menor região que contém o ponto). A cada 0,25 s, publica a zona de cada jogador em atributos (`ZoneKind`, `ZoneTier` e `ZoneName`).
- **Tipos de zona:** ficam em `Config/Zones` (Azul, Cidade, Amarela, Vermelha e Preta), com nome, cor, sorte, fama, PvP, segurança e risco.
- **Inimigos de teste:** ganharam grupos na Amarela T2 (480 e 570 studs) e na Vermelha T3 (720, 800 e 880 studs).

**Para o Davi testar no Studio:**
1. **HUD:** dê Play: o topo mostra a zona Azul de teste.
2. **Trocar de zona:** ande para a esquerda (fora de combate). Aos 250 studs entra na cidade, aos 400 na Amarela e aos 650 na Vermelha, e o topo e a faixa mudam a cada vez.
3. **Inimigos herdam a zona:** os bandidos da Amarela têm mais vida que os da Azul (T2), e os da Vermelha mais ainda (T3).
4. **Regiões do Studio:** crie uma parte grande com a tag `Zone` e os atributos `Zone`, `Tier` e `ZoneName`. Com uma região no place, o traçado de teste não aparece.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
