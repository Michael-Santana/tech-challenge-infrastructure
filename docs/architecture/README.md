# Documentacao de arquitetura

Este conjunto descreve o estado encontrado nas branches de trabalho dos repositorios:

- `tech-challenge-os-service` (`feature/os-service`)
- `tech-challenge-billing-service` (`feature/billing-service`)
- `tech-challenge-execution-service` (`feature/execution`)
- `tech-challenge-infrastructure` (`feature/infraestruture`)

Os diagramas Mermaid podem ser visualizados no GitHub. A arquitetura inclui o
ambiente AWS/EKS provisionado e em uso, informado pelo responsavel pelo projeto;
os detalhes de recursos AWS nao mantidos nestes repositorios nao sao presumidos.
Decisoes implementadas estao separadas de propostas ainda abertas.

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
| Nuvem/cluster | AWS/EKS provisionado e em uso. O Terraform deste repositorio cria um Kind efemero para validacao; workflows de servico estao configurados para direcionar o deploy ao cluster externo via `KUBE_CONFIG` (execucao e secrets nao verificados nesta documentacao). |
| Autenticacao | Billing protege `/budgets` por `X-API-Key`; webhook Mercado Pago valida assinatura. OS e Execution nao implementam autenticacao de usuario nas APIs examinadas. |
| Monitoramento | Terraform instala kube-prometheus-stack. Billing tem anotacoes de scrape e Execution tem `ServiceMonitor`; cobertura de descoberta nao e uniforme. |
| Autoscaling | HPA nao encontrado. Deployments estao em replicas fixas, com requests/limits parciais. |
| Exposicao externa | Nao ha Ingress/Gateway nos manifests examinados. Os Services sao internos ao cluster. |

Os detalhes de provisionamento, topologia, regiao, recursos gerenciados e
operacao do ambiente AWS/EKS nao estao versionados nestes repositorios e devem
ser mantidos na documentacao/configuracao operacional AWS. A existencia do
cluster nao comprova, por si so, que workflows, secrets ou deploys estejam
configurados ou operacionais. Revalidar os documentos quando contratos,
manifests ou decisoes forem alterados.
