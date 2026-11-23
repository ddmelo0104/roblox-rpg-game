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
