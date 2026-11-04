# Definições de Pronto

## Definition of Ready: a história pode ir para `pronto` quando
- [ ] Está escrita no formato **Como / quero / para que**
- [ ] Tem **critérios de aceite** testáveis (Dado / Quando / Então)
- [ ] Está ligada a um **épico**
- [ ] Está **estimada** com no máximo 8 pontos (mais que isso: quebrar)
- [ ] As dependências estão resolvidas ou explícitas
- [ ] As decisões técnicas necessárias já têm ADR, ou estão nas notas técnicas
- [ ] O design necessário existe na aba do sistema, no [doc de design](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ), mesmo que em rascunho

Quem move para `pronto` é o arquiteto (Davi).

## Definition of Done: a história é `concluido` quando
- [ ] Todos os critérios de aceite passam no Studio
- [ ] O código segue as [convenções](../arquitetura/CONVENCOES-DE-CODIGO.md): `stylua src` e `selene src` sem erros nem avisos
- [ ] Foi testada com servidor e cliente (Test → Clients and Servers)
- [ ] Tudo o que vem do cliente é validado no servidor
- [ ] Não há erros nem avisos novos no Output
- [ ] Commits no padrão, PR revisado e merge na `main` com o CI verde
- [ ] A documentação afetada foi atualizada (aba de design, arquitetura ou ADR)
- [ ] `concluido_em` preenchido, seção "Revisão / resultado" escrita e `python3 tools/backlog.py` rodado

O dev (Claude) leva a história até `revisao`. Quem marca `concluido` é o Davi, depois de testar.
