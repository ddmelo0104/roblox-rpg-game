---
tipo: historia
id: US-052
titulo: Cidade de Stardawn provisória feita por código
status: revisao
prioridade: must
epico: EP-007
pontos: 5
sprint:
criado: 2026-11-24
atualizado: 2026-11-24
concluido_em:
---

# US-052 · Cidade de Stardawn provisória feita por código

## História
**Como** jogador que chega à cidade,
**quero** ver uma cidade de verdade, com muralha, praça e prédios,
**para que** Stardawn pareça o lugar seguro onde eu guardo, conserto e vendo o que trago.

## Contexto
Pedido do Davi em 24/11: "continue com a ambientação, cidade, estruturas etc.". A zona da cidade era só uma região vazia (US-035).

O que vem do design:
- **Facções:** Stardawn é "a cidade estelar", em rosa e dourado. O brasão é uma estrela de oito pontas de cristal rosa, com contorno dourado e uma gema no centro.
- **Zonas e Risco:** a cidade é segura e tem banco, vendedor e reparo.

Os modelos 3D são do Studio (regra 5). Por isso a cidade é **provisória**: o código só a monta quando o place não tem uma cidade, e o Davi pode "congelá-la" no Studio e editar à mão. O layout é decisão do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)).

## Critérios de aceite
**Cenário 1: a cidade aparece**
- **Dado** um place sem cidade (nenhum modelo com a tag `CityModel`)
- **Quando** o jogo começa
- **Então** a cidade surge no centro de cada zona do tipo Cidade, no chão, com a rua principal ao longo da zona

**Cenário 2: muralha e portões**
- **Dado** a cidade
- **Quando** o jogador chega por um portão
- **Então** vê:
  - a muralha com ameias e torres nos cantos;
  - o portão com torres, estandartes rosa com a estrela dourada, tochas e o brasão em cima;
  - "STARDAWN" escrito do lado de fora, e do lado de dentro o nome, a cor e o tier da zona depois do portão.

**Cenário 3: praça e prédios**
- **Dado** a cidade
- **Quando** o jogador anda por ela
- **Então** encontra:
  - a Praça da Estrela, com o monumento cuja estrela gira e flutua;
  - o Banco de Stardawn, com telhado dourado;
  - a Taverna da Estrela Cadente, o Observatório e a Ferraria, com forja, fogo e fumaça;
  - o mercado com 6 barracas, o poço, 10 casas, postes acesos, bancos e árvores floridas.

**Cenário 4: voltar à cidade**
- **Dado** um jogador que volta à cidade (saque total, US-040, ou desistir numa dungeon da Vermelha, US-049)
- **Quando** ele aparece
- **Então** aparece na rua principal, no centro da cidade, e não dentro de um prédio

**Cenário 5: congelar no Studio**
- **Dado** a cidade copiada para o place no Studio
- **Quando** o jogo começa de novo
- **Então** o código não monta outra cidade

## Notas técnicas (arquiteto → dev)
- Lado: servidor, com uma animação no cliente
- Módulos afetados:
  - `Services/CityService` (novo);
  - `CityBuilder`, `Props` e `Build` (novos, em `src/server`);
  - `Config/City` (layout, medidas e cores);
  - `Shared/World` (tags `CityModel` e `Spin`);
  - `DecorController` (novo): gira as peças com a tag `Spin`, só na tela de cada jogador.
- Remotes: nenhum. Os prédios ainda não têm função: moeda, banco, vendedor e conserto são as próximas histórias.
- Desempenho: cerca de 900 peças ancoradas. A decoração leve não tem colisão nem sombra, e as estrelas giram só perto da câmera.

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima)
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-24):**
- **Medidas:** a cidade tem 140 × 240 studs, dentro da faixa de 150 studs da zona da cidade do layout de teste.
- **Configuração:** posições, tamanhos, placas e cores ficam em `Config/City`. `BUILD_PROVISIONAL = false` desliga a cidade.
- **Centro livre:** o centro da zona fica livre, na rua principal, porque é o ponto de volta à cidade.

**Para o Davi testar no Studio:**
1. **Chegar:** dê Play e siga a estrada para a esquerda do spawn; a cidade começa a 250 studs. Confira a muralha, as torres e o portão.
2. **Portões:** por fora, "STARDAWN"; por dentro, o portão leste mostra "Campos de Stardawn · Zona Azul · T1" e o oeste, "Colinas de Stardawn · Zona Amarela · T2".
3. **Praça:** a estrela do monumento gira devagar e sobe e desce. A estrelinha do observatório gira ao contrário.
4. **Prédios:** confira banco, taverna, ferraria (fogo e fumaça), observatório, mercado, poço e casas. Nada deve atravessar nada.
5. **Volta:** morra com saque total na Vermelha (2 jogadores, H para finalizar). Você deve aparecer na rua principal.
6. **Congelar:**
   - durante o Play, troque para a visão do servidor (Test → Client/Server);
   - no Explorer, copie `Workspace > Stardawn`;
   - pare o Play, cole no `Workspace` e salve.
   - No Play seguinte não deve surgir uma segunda cidade.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
