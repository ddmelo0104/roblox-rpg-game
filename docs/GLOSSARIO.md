# Glossário

## Termos do jogo
Nomes provisórios até o jogo ser batizado. Os detalhes de cada sistema estão nas abas do [doc de design](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ).

| Termo | Significado |
| --- | --- |
| **Aprimoramento** | +1 a +3 num item; cada nível vale o mesmo que um tier ([Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32)) |
| **Bolsa de saque** | O que fica no chão quando alguém morre com saque total ([Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b)) |
| **Derrubado** | Estado com vida 0: dá para levantar, ser reanimado, ser finalizado ou desistir ([Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b)) |
| **Dungeon corrompida** | Dungeon solo com invasão PvP opcional e três dificuldades ([Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738)) |
| **Especialização** | Nível de 0 a 100 num item específico (ex.: Espada Larga); dá GS e habilidades alternativas |
| **Extração** | Voltar à cidade com o loot: "o loot só é seu quando chega no banco" |
| **Fama** | O que se ganha ao lutar; alimenta a especialização e a maestria |
| **Flag PvP** | Marcação que permite atacar e ser atacado por jogadores nas zonas Amarela e Vermelha |
| **GS (Gear Score)** | Poder do equipamento: tier, aprimoramento, raridade, especialização e maestria |
| **GS recomendado** | 100 × tier da zona + 50, mostrado na UI de cada zona |
| **Infâmia** | Progressão própria das dungeons corrompidas |
| **Maestria** | Nível de 0 a 100 numa linha (ex.: Espadas); libera tiers para equipar |
| **Raridade** | Comum, Incomum, Raro, Épico ou Lendário; dá GS extra |
| **Saque total** | Morrer e deixar cair tudo o que se veste e carrega |
| **Sorte da zona** | Multiplicador que melhora as chances de raridade nas zonas de risco |
| **Teto suave de GS** | Limite acima do qual só parte do GS conta, para nivelar conteúdos como o PvP |
| **Tier** | Nível de um item ou de uma zona (T1 a T8) |
| **Tier equivalente** | Tier + aprimoramento; é o que vale para o requisito de maestria |
| **Zona** | Área do mundo com cor (risco) e tier (dificuldade): Azul, Amarela, Vermelha, Preta e conteúdos Laranja |

## Termos de engenharia e Roblox

| Termo | Significado |
| --- | --- |
| **ADR** | *Architecture Decision Record*, registro curto de uma decisão técnica |
| **Combat logging** | Sair do jogo no meio do combate para escapar da morte |
| **Core loop** | Ciclo de ações que o jogador repete a todo momento |
| **DataStore** | Serviço do Roblox para salvar os dados do jogador entre sessões |
| **DoD / DoR** | *Definition of Done / Ready*, os checklists de pronto |
| **Duplicação (dupe)** | Falha que faz um item existir em dois lugares; o maior risco de jogos com troca |
| **Épico** | Bloco grande de valor, dividido em várias histórias |
| **História (US)** | *User story*, a menor entrega com valor que dá para testar |
| **Luau** | Linguagem do Roblox, derivada de Lua, com tipos opcionais |
| **Marco** | Ponto do roadmap com algo jogável (M0 a M3) |
| **Meta loop** | O que faz o jogador voltar amanhã |
| **ModuleScript** | Script reutilizável, carregado com `require` |
| **MoSCoW** | Priorização em *Must, Should, Could, Won't* |
| **Place** | Um "mapa" dentro do universo do jogo no Roblox; cada place tem seus próprios servidores |
| **RemoteEvent / RemoteFunction** | Comunicação entre cliente e servidor |
| **Reserved server** | Servidor privado criado pelo jogo, usado para instâncias como dungeons |
| **Rojo** | Sincroniza os arquivos do disco com o Roblox Studio |
| **Rokit** | Gerenciador de versões das ferramentas (Rojo, Selene…) |
| **Selene / StyLua** | Lint e formatação de código Luau |
| **Servidor autoritativo** | O servidor decide o estado; o cliente só pede |
| **Session locking** | Trava que impede o mesmo perfil de ser carregado em dois servidores ao mesmo tempo |
| **Skill (Claude Code)** | Instrução empacotada que o Claude Code segue para uma tarefa recorrente, como implementar uma história |
| **Story points** | Estimativa relativa de esforço e complexidade |
| **StreamingEnabled** | Recurso do Roblox que carrega só a parte do mapa perto do jogador |
| **Vertical slice** | Pedaço pequeno do jogo com qualidade quase final |
| **Wally** | Gerenciador de pacotes da comunidade Roblox |
