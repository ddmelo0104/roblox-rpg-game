# Decisões delegadas

Em 23/11/2026, o Davi pediu ao dev para tomar as decisões de game design que faltarem "como ele pensa" e seguir construindo o jogo, e disse que ajusta depois. Este arquivo registra cada uma dessas decisões, para ele revisar num lugar só.

**Como o dev decide:**
1. Segue o doc de design e as decisões anteriores do Davi.
2. Quando a aba já tem uma proposta (marcada como "proposta"), adota essa proposta.
3. Quando não tem, escolhe o mais simples, alinhado ao Albion e aos Pilares de Design, que dê para mudar só no Config.

Para mudar uma decisão, edite a linha (ou me peça) e eu ajusto o código e as histórias.

| Data | Sistema | Decisão | Por quê | Onde |
| --- | --- | --- | --- | --- |
| 2026-11-23 | Combate | "Em combate" dura 15 s depois de causar ou levar dano | É o `TEMPO_COMBATE` já proposto na aba Zonas e Risco | `Config/Combat.COMBAT_TIME`, [US-015](historias/US-015-estado-de-combate-e-pulo-limitado.md) |
| 2026-11-23 | Movimentação | O pulo limitado em combate é um intervalo de 1,5 s entre pulos | O Davi pediu o pulo limitado. Um intervalo impede o pula-pula e mantém o pulo para desviar de obstáculos | `Config/Movement.JUMP_COOLDOWN_IN_COMBAT`, [US-015](historias/US-015-estado-de-combate-e-pulo-limitado.md) |
| 2026-11-23 | Movimentação | A corrida continua livre em combate | O gasto de energia da corrida ficou para depois (Davi), e bloquear a corrida sem um custo deixaria a luta parada | [US-015](historias/US-015-estado-de-combate-e-pulo-limitado.md) |
| 2026-11-23 | Combate | Toda arma pode aparar; o parry é uma ação de defesa de todos, e não uma habilidade da arma | É a pergunta aberta "todas as armas têm parry?". Uma defesa igual para todos é mais simples de aprender e de balancear no M1 | [US-013](historias/US-013-esquiva-e-parry.md) |
| 2026-11-23 | Planejamento | Ordem do M1: itens (EP-004), combate por equipamento (EP-003), inimigos (EP-008), progressão (EP-005), persistência (EP-006), mundo e zonas (EP-007), morte e saque (EP-009), dungeon solo (EP-010), interface e tutorial (EP-011) e grupo (EP-012) | Segue as dependências dos épicos e chega o quanto antes no ciclo matar, saquear e equipar | [ROADMAP](ROADMAP.md) |
| 2026-11-23 | Itens | Os bônus por peça de armadura: leve +4% de dano e −4% de cooldown; média +3% de dano e +5% de vida; tanque +10% de vida, 6% de resistência e −2% de cooldown | Seguem os tipos que o Davi definiu em 04/11, com valores pequenos por peça, para que misturar peças valha a pena | `Config/Items.ARMOR_BONUSES`, [US-016](historias/US-016-catalogo-de-itens-e-gs.md) |
| 2026-11-23 | Itens | Resistência máxima de 75% e cooldown mínimo de 25% do original | Nenhuma combinação deixa alguém imune ou sem cooldown | `Config/Items` |
| 2026-11-23 | Itens | As linhas de armadura viram Tecido (leve), Couro (média) e Placa (tanque), com 3 peças cada | Junta a aba Progressão (linhas) com os tipos do Davi (leve, média e tanque) | `Config/Items.ITEMS` |
| 2026-11-23 | Itens | A mochila tem 24 espaços | Metade do Albion: no M1 há pouco item, e a escolha do que carregar fica com peso | `Config/Items.INVENTORY_SIZE` |
| 2026-11-23 | Itens | O kit inicial é Espada longa e armadura de couro (média) completa, T1 Comum, equipados | É o kit de recomeço da aba Zonas e Risco; a armadura média é o meio-termo para quem está aprendendo | `Config/Items.STARTER_KIT`, [US-017](historias/US-017-inventario-no-servidor.md) |
| 2026-11-23 | Itens | Vida base de 100 (o padrão do Roblox), escalada pelo GS e pelos bônus | Mantém os números do protótipo e deixa o equipamento decidir a diferença | `Config/Combat.BASE_HEALTH` |
| 2026-11-23 | Itens | Um item quebrado (0% de durabilidade) não conta GS nem dá bônus | A aba Progressão diz que o item quebrado não conta GS; tirar o bônus junto segue a mesma ideia | `Shared.Items` |
| 2026-11-23 | Loot | Um baú de teste perto do spawn, com o sorteio de inimigo comum (T1, sorte 1) | Dá para testar o inventário e o equipamento antes dos inimigos (EP-008) | [US-020](historias/US-020-sorteio-de-loot-e-bau-de-teste.md) |
| 2026-11-23 | Interface | A tecla I abre o inventário, como no Albion | As teclas do PC são pergunta aberta; I é o padrão que os jogadores do gênero já conhecem | `Config/Interface.INVENTORY_KEY` |
