# Documentacao de arquitetura

Este conjunto descreve o estado encontrado nas branches de trabalho dos repositorios:

- `tech-challenge-os-service` (`feature/os-service`)
- `tech-challenge-billing-service` (`feature/billing-service`)
- `tech-challenge-execution-service` (`feature/execution`)
- `tech-challenge-infrastructure` (`feature/infraestruture`)

Os diagramas Mermaid podem ser visualizados no GitHub. Decisoes implementadas
estao separadas de propostas ainda abertas; uma proposta nao representa
configuracao existente nem decisao aprovada.

## Documentos

- [Visao arquitetural e diagramas](architecture.md): componentes, contexto de
  infraestrutura, autenticacao como implementada e abertura de OS/Saga.
- [Modelo de dados e justificativa](data-model.md): justificativa dos bancos,
  diagramas ER/documentais e limites de consistencia entre servicos.
- [RFCs e ADRs](decisions/README.md): decisoes, alternativas, status e
  consequencias tecnicas.

## Estado resumido

| Tema | Estado observado |
|---|---|
| Orquestracao distribuida | Saga coreografada por eventos RabbitMQ, com outbox nos servicos OS e Billing e eventos pendentes no documento de Execution. |
| Bancos | PostgreSQL para OS e Billing; MongoDB para historico OS e estado/execucao. Bancos separados por servico. |
| Nuvem/cluster | Nenhum provedor de nuvem de producao selecionado no Terraform. A validacao cria cluster Kind efemero; os workflows de servico esperam um cluster externo via `KUBE_CONFIG`. |
| Autenticacao | Billing protege `/budgets` por `X-API-Key`; webhook Mercado Pago valida assinatura. OS e Execution nao implementam autenticacao de usuario nas APIs examinadas. |
| Monitoramento | Terraform instala kube-prometheus-stack. Billing tem anotacoes de scrape e Execution tem `ServiceMonitor`; cobertura de descoberta nao e uniforme. |
| Autoscaling | HPA nao encontrado. Deployments estao em replicas fixas, com requests/limits parciais. |
| Exposicao externa | Nao ha Ingress/Gateway nos manifests examinados. Os Services sao internos ao cluster. |

Esta documentacao e baseada no codigo e manifestos dessas branches, nao declara
que os workflows, clusters ou secrets externos estejam operacionais. Revalidar
os documentos quando contratos, manifests ou decisoes forem alterados.
