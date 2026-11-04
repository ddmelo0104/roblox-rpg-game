# Como trabalhar com o Claude

| Papel | Quem | Faz |
| --- | --- | --- |
| Engenheiro de software e arquiteto | Davi | Define visão e prioridades, escreve épicos e histórias, toma as decisões (ADRs), revisa e aceita |
| Dev | Claude | Propõe opções técnicas, implementa histórias, escreve testes e documentação técnica, aponta riscos e dúvidas antes de codar |

## Onde cada coisa acontece
- **Design do jogo:** no [doc de design](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ), no Claude Docs. É lá que a Visão, os Pilares e os Sistemas são discutidos e editados, inclusive por comentários.
- **Código e planejamento de engenharia:** neste repositório, pelo Claude Code. O Claude lê e escreve os arquivos direto e roda `stylua`, `selene`, `rojo build` e `tools/backlog.py`.

## Ciclo de uma história

```mermaid
sequenceDiagram
  participant D as Davi (arquiteto)
  participant C as Claude (dev)
  D->>D: Escreve a história com critérios de aceite e move para "pronto"
  D->>C: /implementar-historia US-XXX
  C->>D: Suposições, dúvidas e plano curto
  D->>C: Responde ou ajusta
  C->>C: Branch, código, stylua, selene, rojo build
  C->>D: PR + passo a passo para testar no Studio (status "revisao")
  D->>D: Testa no Studio e revisa o diff
  alt passou
    D->>D: Merge e status "concluido"
  else falhou
    D->>C: Feedback no PR ou um BUG-XXX
  end
```

## Skills do projeto (Claude Code)
| Comando | Para quê |
| --- | --- |
| `/implementar-historia US-XXX` | Implementa uma história seguindo o processo inteiro |
| `/nova-historia <título>` | Cria uma história com o próximo ID livre, a partir do template |
| `/novo-adr <decisão>` | Registra uma decisão técnica com o próximo número livre |

Também dá para pedir em português normal ("implemente a US-005"): o Claude Code reconhece a skill pela descrição.

## Regras de ouro
1. **Uma história por vez.** Pedidos grandes geram código grande e difícil de revisar.
2. **Critério de aceite primeiro.** Sem ele, não há como saber se está pronto.
3. **Decisão difícil vira ADR,** mesmo que curto.
4. **Revise o diff.** O Davi é o responsável técnico. O Claude erra, e também precisa dizer quando não tem certeza.
