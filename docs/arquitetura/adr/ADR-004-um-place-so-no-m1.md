---
tipo: adr
id: ADR-004
titulo: Um place só no M1, com as zonas como regiões de dados
status: proposto
epicos: EP-007
criado: 2026-11-23
decidido_em:
substitui:
substituido_por:
---

# ADR-004 · Um place só no M1, com as zonas como regiões de dados

> [!NOTE]
> Status: **proposto** → aceito → (obsoleto | substituído).

## Contexto
O M1 tem uma região, Stardawn, com a zona Azul de tutorial, a cidade, uma zona Amarela e uma Vermelha em linha (corte aprovado pelo Davi em 04/11; aba Zonas e Risco). É preciso decidir se o mundo é um place só ou um place por zona.

O Roblox aceita até 200 jogadores por servidor, mas, para jogos com muito combate, a sugestão prática do DevForum fica entre 50 e 100 (visão arquitetural). "Muitos jogadores no mundo" vira, então, vários servidores. O princípio 5 da aba Zonas e Risco diz que as regras da zona são dados, nunca código especial.

## Opções consideradas
### Opção A: um place só, com as zonas como regiões de dados
As zonas são partes com a tag `Zone` e os atributos `Zone` (tipo), `Tier` e `ZoneName`, feitas no Studio junto com o terreno. O servidor descobre em que zona cada jogador está e aplica as regras do `Config/Zones`.
- Prós:
  - Sem teleporte nem telas de carregamento: andar da Azul à Vermelha é contínuo, como no Albion dentro de um mapa.
  - Mais simples de testar no Studio: um Play só tem tudo.
  - O estado (inventário, combate, bolsas) não atravessa servidores.
- Contras:
  - Todos os jogadores do servidor dividem o mesmo mundo, e o limite de jogadores vale para a região inteira.
  - O mapa inteiro pesa num servidor e precisa do StreamingEnabled (orçamento do spike da US-014).

### Opção B: um place por zona, ligados por TeleportService
- Prós: cada zona escala sozinha, com servidores próprios; mapas mais leves.
- Contras:
  - Teleporte com tela de carregamento a cada fronteira.
  - O perfil precisa ser salvo e solto a cada troca, o que aumenta o risco de duplicação na trava de sessão (ADR-005).
  - Testar exige o jogo publicado.

## Decisão
> [!IMPORTANT]
> **Proposta: opção A no M1.** As zonas são regiões de dados num place só, e o `ZoneService` diz a zona de cada ponto.
> Como as regras já são dados, passar para a opção B depois (M2 ou M3, com Tenebrarum, Verdantis e a zona Preta pelo portal) não muda as regras; muda só onde cada zona roda.

Detalhes já implementados no EP-007 (US-035 a US-037):
- **Regiões:** uma região é uma caixa (qualquer rotação). Num ponto dentro de duas, vale a menor, então dá para pôr uma zona dentro de outra.
- **Fora de toda região:** vale a zona padrão do `Config/Zones` (Azul, T1).
- **Leitura no `Init`:** o `ZoneService` lê as regiões no `Init`, antes de os serviços começarem, para os pontos de spawn de inimigos herdarem o tier e o tipo da zona.
- **Place sem regiões:** aparece um traçado de teste à esquerda do spawn, para testar num Baseplate.

## Consequências
- **Positivas:** o mundo do M1 é contínuo, e as zonas são criadas só no Studio, sem código.
- **Negativas e trade-offs aceitos:** o limite de jogadores por servidor vale para a região toda no M1.
- **O que passa a ser obrigatório:**
  - Toda regra que muda por zona fica no `Config/Zones`.
  - O código consulta o `ZoneService` em vez de comparar posições.

## Referências
- Aba Zonas e Risco do doc de design (Mundo, fronteiras e viagem; Variáveis).
- Visão arquitetural: jogadores por servidor e fontes do DevForum.
