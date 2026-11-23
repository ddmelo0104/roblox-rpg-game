---
tipo: historia
id: US-033
titulo: Perfil salvo com trava de sessão
status: revisao
prioridade: must
epico: EP-006
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-033 · Perfil salvo com trava de sessão

## História
**Como** jogador,
**quero** que o meu perfil seja salvo e que ninguém consiga abri-lo em dois servidores ao mesmo tempo,
**para que** eu nunca perca o progresso e ninguém duplique itens trocando de servidor.

## Contexto
Escopo do EP-006 e regra 6 do `CLAUDE.md`. A forma de salvar é a do [ADR-005](../../arquitetura/adr/ADR-005-perfil-salvo-com-trava-de-sessao.md) (proposto pelo dev, esperando o Davi): DataStore com trava de sessão própria, atrás de um `ProfileService` com seções.

## Critérios de aceite
**Cenário 1: salvar e voltar**
- **Dado** um jogador num place publicado, com o acesso às APIs ligado no Studio
- **Quando** ele sai e entra de novo
- **Então** o perfil volta como estava no último salvamento

**Cenário 2: salvamento periódico**
- **Dado** um jogador jogando
- **Quando** passam 60 s
- **Então** o perfil é salvo, sem soltar a trava

**Cenário 3: troca de servidor**
- **Dado** o perfil aberto no servidor A
- **Quando** o jogador entra no servidor B antes de A terminar de salvar
- **Então** B espera A soltar a trava (até 6 tentativas, a cada 5 s) e só então carrega; se não conseguir, expulsa com "Não foi possível carregar o seu perfil agora…"

**Cenário 4: trava perdida**
- **Dado** um servidor cuja trava foi tomada (o anterior caiu e a trava morreu)
- **Quando** ele tenta salvar
- **Então** não grava nada e expulsa o jogador com "O seu perfil foi aberto em outro servidor."

**Cenário 5: servidor fechando**
- **Dado** jogadores no servidor
- **Quando** ele fecha
- **Então** todos os perfis são salvos e soltos, em até 25 s

**Cenário 6: Studio sem APIs**
- **Dado** o Studio sem acesso às APIs (ou o place não publicado)
- **Quando** o jogo começa
- **Então** o Output avisa que o DataStore não está disponível, e o perfil fica só na memória

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados: `Services/ProfileService` (novo), `Config/Profile` (novo)
- Remotes e validação no servidor: nenhum; o cliente não toca no perfil
- Dados persistidos: DataStore `PlayerProfiles_v1`, chave `Player_<UserId>`: `{ version, data, lock }`

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Seções:** cada serviço registra uma seção no `Init` (`load`, `save` e `release`).
- **Carregar:** o `ProfileService` carrega o perfil quando o jogador entra e entrega a cada seção a parte dela.
- **Salvar:** a cada 60 s, ao sair e quando o servidor fecha, sempre com `UpdateAsync` conferindo a trava.
- **Soltar:** nenhum serviço apaga dados no `PlayerRemoving`. O `ProfileService` copia tudo para o último salvamento e só então pede às seções para soltar. Isso evita salvar um inventário vazio por causa da ordem dos eventos.
- **Seção com falha:** se uma seção falha ao carregar, o jogador é expulso com o aviso, em vez de jogar sem salvar.
- **Números:** em `Config/Profile`.

**Limite desta sessão:** a documentação oficial do DataStore não pôde ser aberta, porque a rede do ambiente bloqueou o `create.roblox.com`. Os comportamentos que o código assume estão listados no ADR-005, para conferir.

**Para o Davi testar no Studio:**
1. **Preparar:** publique o place (File → Publish to Roblox) e ligue Game Settings → Security → "Enable Studio Access to API Services".
2. **Salvar e voltar:** dê Play, pegue itens no baú de teste e derrote uns bandidos. Pare o Play e dê Play de novo: a mochila, o equipamento e a maestria (N) continuam.
3. **Sem APIs:** desligue o acesso às APIs e dê Play. O Output avisa "[Profile] DataStore unavailable…", e o jogo funciona sem salvar.
4. **Troca de servidor (opcional, no Roblox):** entre no jogo publicado em dois servidores seguidos com a mesma conta. O segundo só carrega depois que o primeiro solta a trava, e os itens não se duplicam.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
