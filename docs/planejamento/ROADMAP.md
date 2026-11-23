# Roadmap

Marcos são resultados, não datas: cada um termina com algo jogável e verificável. As datas entram quando houver velocidade medida, depois de 2 ou 3 sprints.

```mermaid
flowchart LR
  M0["M0 · Fundação<br/>base técnica e protótipo do núcleo"] --> M1["M1 · Vertical Slice<br/>1 área, core loop completo"]
  M1 --> M2["M2 · Alpha<br/>sistemas do MVP, conteúdo provisório"]
  M2 --> M3["M3 · Beta / Lançamento<br/>conteúdo final, polimento, playtests"]
```

| Marco | Saída esperada | Situação |
| --- | --- | --- |
| M0 · Fundação | Fundação pronta (Rojo, GitHub, lint, formatação, CI, convenções e um exemplo cliente↔servidor validado) e o núcleo provado no PC: protótipo de combate, movimento e câmera e spike de desempenho do terreno ([EP-001](epicos/EP-001-base-tecnica-e-prototipo-do-nucleo.md)) | Em andamento |
| M1 · Vertical Slice | Um pedaço pequeno do jogo com qualidade próxima da final, que prova que o core loop é divertido (cerca de 30 minutos de jogo) | Corte aprovado em 04/11 (só PC, região de Stardawn); épicos EP-002 a EP-012 criados em 05/11 |
| M2 · Alpha | Todos os sistemas do MVP, com conteúdo provisório | — |
| M3 · Beta / Lançamento | Conteúdo final, polimento e playtests | — |

## Ordem de construção do M1
Decidida pelo dev em 23/11, por delegação do Davi, seguindo as dependências entre os épicos. As histórias de cada épico são escritas quando a vez dele chega.

1. **EP-004** · Itens, inventário, equipamento e GS (em revisão: US-016 a US-020).
2. **EP-003** · Combate e habilidades por equipamento: kit de cada arma, ataque básico, peitoral e botas (em revisão: US-021 a US-024).
3. **EP-008** · Inimigos, IA e facções, com drops pelo sorteio da US-020 (em revisão: US-025 a US-028).
4. **EP-005** · Fama, maestria e especialização (em revisão: US-029 a US-032; as habilidades alternativas vêm depois do EP-006).
5. **EP-006** · Persistência do perfil (ADR-005, proposto) (em revisão: US-033 e US-034).
6. **EP-007** · Mundo de Stardawn: o código das zonas. O terreno é feito pelo Davi no Studio (em revisão: US-035 a US-037; faltam o mapa e a cidade).
7. **EP-009** · Morte, derrubado e saque (em revisão: US-038 a US-040; falta o anti *combat logging*).
8. **EP-010** · Dungeon aleatória solo (próximo).
9. **EP-011** · HUD, UI e a quest de tutorial.
10. **EP-012** · Conteúdo de grupo.

O EP-002 (personagem, câmera e controles) já foi quase todo coberto pelas histórias do EP-001 (US-009 a US-011 e US-015). O que faltar vai junto com o EP-011.

Os épicos de cada marco aparecem no [BACKLOG.md](BACKLOG.md). O corte aprovado do M1 está na aba [Visão do Jogo](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ) do doc de design, e os épicos dele (EP-002 a EP-012) estão em `epicos/`. Os candidatos de M2 em diante ainda não viraram arquivos:

| # | Épico candidato | Marco | Depende de |
| --- | --- | --- | --- |
| EP-013 | Mercado entre jogadores | M2 | EP-004, EP-006 |
| EP-014 | Flag PvP e reputação | M2 | EP-009 |
| EP-015 | Dungeon corrompida | M2 | EP-010, EP-014 |
| EP-016 | Grupo e guildas | M3 | EP-012 |
| EP-017 | Monetização (VIP e cosméticos) | M3 | EP-004 |
| EP-018 | Versão para celular (controles e UI) | a definir | EP-002, EP-011 |
