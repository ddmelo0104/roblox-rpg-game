---
tipo: historia
id: US-037
titulo: Fronteira travada em combate, proteção de entrada e aviso de risco
status: revisao
prioridade: must
epico: EP-007
pontos: 3
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-037 · Fronteira travada em combate, proteção de entrada e aviso de risco

## História
**Como** jogador,
**quero** que ninguém fuja pela fronteira no meio da luta, que quem chega numa zona de PvP tenha uns segundos de proteção, e ser avisado antes de arriscar tudo,
**para que** as zonas sejam justas e o risco seja sempre avisado.

## Contexto
Aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b):
- **Fronteira:** `TEMPO_COMBATE` (15 s) bloqueia a troca de zona.
- **Proteção de entrada:** `PROTECAO_ENTRADA` (10 s) some ao atacar.
- **Cidade:** é segura.
- **Zona Vermelha:** ao entrar, aviso em tela cheia na primeira vez e borda vermelha enquanto estiver nela.

Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Qualquer troca de zona** é bloqueada em combate: o jogador volta ao último lugar da zona antiga.
- **A proteção** vale só contra jogadores e acaba com qualquer ataque.
- **Na cidade,** ninguém toma dano, nem de inimigo.
- **O aviso de risco** aparece uma vez por sessão.

## Critérios de aceite
**Cenário 1: fronteira em combate**
- **Dado** um jogador em combate (levou ou causou dano há menos de 15 s)
- **Quando** ele tenta passar para outra zona
- **Então** volta para onde estava e vê "Zona: em combate, não dá para trocar de zona"

**Cenário 2: proteção de entrada**
- **Dado** um jogador entra na zona Vermelha
- **Quando** outro jogador tenta atacá-lo nos primeiros 10 s
- **Então** o golpe não o acerta, e o HUD dele mostra "Protegido de outros jogadores: N s"

**Cenário 3: a proteção acaba ao atacar**
- **Dado** um jogador protegido
- **Quando** ele ataca alguém
- **Então** a proteção acaba na hora

**Cenário 4: cidade segura**
- **Dado** um jogador na cidade de teste
- **Quando** um inimigo ou outro jogador tenta acertá-lo
- **Então** ele não toma dano

**Cenário 5: aviso de risco**
- **Dado** um jogador que ainda não entrou numa zona de risco nesta sessão
- **Quando** ele entra na Vermelha
- **Então** aparece em tela cheia "Zona de risco · Aqui você pode perder tudo o que carrega", e a borda da tela fica vermelha enquanto ele estiver lá

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `ZoneService` (fronteira e proteção), `DefenseService` (resultado "Immune" na cidade, sem aviso aos clientes), `CombatService` (atacar acaba a proteção), `ZoneController` (aviso, borda e contagem), `Notices`
- Remotes e validação no servidor: o aviso da fronteira usa o Remote `Notice`; a volta usa `MovementValidationService.teleport`
- Dados persistidos: nenhum (o aviso de risco ainda não fica salvo no perfil)

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Fronteira:** o `ZoneService` guarda o último lugar de cada jogador na zona dele. Se o jogador em combate aparece em outra zona, ele volta para lá. O teleporte passa pela validação de movimento, para não contar como trapaça.
- **Proteção:** entrar numa zona com PvP grava `ProtectedUntil` (10 s), e qualquer habilidade ou ataque básico apaga.
- **Cidade:** o `DefenseService` ignora golpes em jogadores numa zona segura.

**Para o Davi testar no Studio:**
1. **Fronteira:** na Azul de teste, provoque o grupo de bandidos dos 210 studs (elite) e corra para a cidade (250 studs) ainda em combate. Você volta e vê o aviso. Espere 15 s sem lutar e passe.
2. **Aviso de risco:** ande até a Vermelha (650 studs). Aparece o aviso em tela cheia por 5 s, a borda fica vermelha e o topo mostra "Protegido de outros jogadores".
3. **Cidade segura:** leve um bandido até a beira da cidade e entre (fora de combate). Os golpes dele não tiram vida.
4. **Proteção com 2 jogadores:** um entra na Vermelha, e o outro, já lá, tenta acertá-lo nos primeiros 10 s. Não acerta. Se o protegido atacar, a proteção acaba.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
