---
tipo: adr
id: ADR-005
titulo: Perfil salvo no DataStore com trava de sessão própria
status: proposto
epicos: EP-006
criado: 2026-11-23
decidido_em:
substitui:
substituido_por:
---

# ADR-005 · Perfil salvo no DataStore com trava de sessão própria

> [!NOTE]
> Status: **proposto** → aceito → (obsoleto | substituído).

## Contexto
O perfil do jogador (mochila, equipamento, fama e maestria; depois o banco e a moeda) precisa sobreviver a saídas, quedas e trocas de servidor sem perder nada e sem duplicar itens (regra 6 do `CLAUDE.md`, [ADR-006](ADR-006-itens-como-registros-com-uid-do-servidor.md)).

O risco clássico é a duplicação ao trocar de servidor. O servidor B carrega o perfil antes de o servidor A terminar de salvar, e os dois ficam com os mesmos itens. A defesa é a **trava de sessão**: só um servidor por vez abre o perfil, e um servidor que perdeu a trava nunca grava por cima.

A visão arquitetural deixou a escolha em aberto: DataStore puro ou uma biblioteca com trava de sessão. Esta é a decisão proposta pelo dev para o EP-006.

## Opções consideradas
### Opção A: DataStore com trava de sessão própria
Um `ProfileService` do projeto guarda cada perfil numa chave do DataStore com um campo `lock`:
- **Carregar:** um `UpdateAsync` toma a trava se ela estiver livre, for deste servidor ou estiver morta (sem salvar há 5 minutos).
- **Trava de outro servidor vivo:** tenta de novo algumas vezes; se não conseguir, expulsa o jogador com um aviso.
- **Salvar:** grava só se a trava ainda for deste servidor; ao sair, solta a trava.
- Prós:
  - Pouco código (um módulo), todo nosso e fácil de revisar.
  - Nenhuma dependência de terceiros e nenhuma ferramenta nova.
  - As seções (`inventory`, `mastery`…) deixam cada serviço dono dos seus dados.
- Contras:
  - Não tem o que uma biblioteca madura tem, como avisar o servidor antigo por MessagingService para soltar a trava na hora.
  - Depois de uma queda de servidor, o jogador espera a trava morrer (5 minutos) para entrar de novo.
  - Casos raros de falha do DataStore são responsabilidade nossa.

### Opção B: ProfileStore (biblioteca da comunidade)
Biblioteca do loleris, mantida pela MadStudioRoblox, sucessora do ProfileService. Segundo o README, ela salva periodicamente com trava de sessão e resolve conflitos de trava entre servidores com poucas chamadas ao DataStore e ao MessagingService. É um ModuleScript só, e o repositório tem `wally.toml` (o `rokit.toml` já traz o Wally).
- Prós:
  - Muito usada e testada em jogos grandes.
  - Resolve a troca rápida de servidor e a queda de servidor melhor que a opção A.
- Contras:
  - Código de terceiros (licença Apache-2.0, pela barra lateral do repositório) para baixar, revisar e manter atualizado.
  - Dependência nova no repositório e no CI (Wally ou cópia do módulo).
  - API própria, que o resto do código precisa conhecer.

### Opção C: DataStore sem trava (`GetAsync` e `SetAsync`)
- Prós: o mais simples.
- Contras: não impede dois servidores de abrirem o mesmo perfil, ou seja, permite a duplicação que a regra 6 proíbe. **Descartada.**

## Decisão
> [!IMPORTANT]
> **Proposta: opção A no M1,** atrás da interface do `ProfileService` (seções com `load`, `save` e `release`). Se o Davi preferir a opção B, só o `ProfileService` muda: os serviços continuam registrando seções.
> **Rever antes do mercado entre servidores (ADR-008, M2)** ou se as esperas por trava aparecerem nos testes.

Detalhes da opção A, já implementados no EP-006 (US-033 e US-034):
- **Chave e formato:** `PlayerProfiles_v1`, chave `Player_<UserId>`, valor `{ version, data = { inventory, mastery }, lock }`. A `version` permite migrar formatos antigos ao carregar.
- **Trava:** `lock = { id, jobId, placeId, savedAt }`. O `id` é um GUID novo por servidor, porque no Studio o `JobId` é vazio.
  - A trava morre depois de 300 s sem salvar.
  - No Studio, uma trava de outro teste do Studio (`jobId` vazio) não bloqueia o próximo teste.
- **Salvamentos:** a cada 60 s, ao sair e no `BindToClose` (até 25 s). Os números ficam em `Config/Profile`.
- **Falhas:**
  - Perfil que não carrega, ou seção que falha ao carregar: o jogador é expulso com um aviso, em vez de jogar sem salvar.
  - Servidor que perde a trava: nunca mais grava e expulsa o jogador.
- **Studio sem acesso às APIs:** os perfis ficam só na memória, com um aviso no Output.

## Consequências
- **Positivas:** perfil salvo sem duplicação ao trocar de servidor; inventário e fama sobrevivem entre sessões; o formato tem versão desde o início.
- **Negativas e trade-offs aceitos:**
  - Depois de uma queda de servidor, o jogador pode esperar até 5 minutos para entrar de novo.
  - Uma falha longa do DataStore pode voltar o perfil ao último salvamento bom. Isso é perda de progresso recente, nunca duplicação.
- **O que passa a ser obrigatório:**
  - Tudo o que vai para o perfil é uma seção do `ProfileService`.
  - Nenhum serviço apaga os dados de um jogador no `PlayerRemoving`: quem solta é o `ProfileService`, depois de copiar para o último salvamento.
  - Para testar no Studio, o place precisa estar publicado, com "Enable Studio Access to API Services" ligado nas Game Settings.

## Referências
> [!WARNING]
> Nesta sessão, a rede do ambiente bloqueou o `create.roblox.com`, então a documentação oficial **não foi aberta**. Os comportamentos abaixo são os que o código assume; confira-os ao aceitar o ADR:
> - **`UpdateAsync`:** a função de transformação pode rodar mais de uma vez, não pode ceder (*yield*), e retornar `nil` cancela a gravação.
> - **`BindToClose`:** o servidor espera no máximo 30 s.
> - **Limites:** a mesma chave aceita uma gravação a cada poucos segundos, e um valor tem até 4 MB.
> - **Studio:** os data stores só funcionam num place publicado, com o acesso às APIs ligado.

- Data stores: https://create.roblox.com/docs/cloud-services/data-stores
- `GlobalDataStore:UpdateAsync`: https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore#UpdateAsync
- `DataModel:BindToClose`: https://create.roblox.com/docs/reference/engine/classes/DataModel#BindToClose
- ProfileStore (README lido em 23/11): https://github.com/MadStudioRoblox/ProfileStore
