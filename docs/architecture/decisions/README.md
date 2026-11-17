# RFCs e ADRs

RFCs registram alternativas/decisoes que ainda requerem avaliacao. ADRs registram
decisoes permanentes ou o estado arquitetural que os repositorios implementam.
`Aceito` significa aceito para o escopo atual do projeto; nao substitui revisao
para producao.

## RFCs

Nao ha RFCs de escolha de provedor abertas neste momento. A decisao de nuvem foi
registrada como ADR-004 abaixo; detalhes de implementacao continuam pendentes.

### RFC-002 — Identidade e autenticacao de APIs

- **Status:** Aberto — estado atual parcial, arquitetura de identidade final nao
  definida.
- **Contexto:** `/budgets/**` requer `X-API-Key` configurada no Billing. O
  webhook Mercado Pago valida assinatura. Os endpoints OS e Execution examinados
  nao aplicam autenticacao/autorizacao; nao existe fluxo de login ou token de
  usuario comum.
- **Alternativas:** autenticacao no API Gateway com OIDC/OAuth2; validacao
  OAuth2/JWT em cada servico; credenciais fortes de workload (mTLS ou identidade
  curta) para comunicacao servico-a-servico; chave estatica por servico.
- **Recomendacao para avaliacao:** OIDC/OAuth2 para usuarios no gateway ou nos
  servicos, autorizacao por papel/escopo e credencial de workload independente
  para chamadas internas. Manter assinatura especifica do Mercado Pago para
  webhooks. Migrar gradualmente a chave estatica do Billing para credencial
  rotacionavel, com audience/escopo e auditoria.
- **Seguranca:** nao expor as APIs OS/Execution ou endpoints de escrita do
  Billing publicamente antes de definir controles equivalentes. Nao reutilizar
  a API key como token de usuario nem desativar validacao de webhook.
- **Consequencias:** a solucao atual serve apenas como controle parcial entre
  sistemas confiaveis; autenticacao/autorizacao de usuarios e uma lacuna.

## ADRs

### ADR-001 — Coreografia da Saga por eventos

- **Status:** Aceito para o fluxo atual.
- **Decisao:** os servicos publicam/consomem eventos por RabbitMQ, sem um
  orquestrador central. A OS e Billing mantem outbox transacional; OS registra
  inbox; Execution registra IDs processados e eventos pendentes no agregado.
- **Motivacao:** os dominios mantem autonomia e a coordenacao ocorre sem
  transacao distribuida. O broker desacopla disponibilidade e ritmo dos
  produtores/consumidores.
- **Consequencias:** consistencia eventual, necessidade de idempotencia,
  retries, DLQ, correlacao e monitoramento. O fluxo exige reconciliacao de
  mensagens e limites claros de cada transicao.
- **Compensacao:** rejeicao cancela a execucao/OS conforme eventos; falha
  definitiva depois de pagamento exige estorno manual (`refundRequired`), nao
  rollback automatico do Mercado Pago.
- **Limite conhecido:** o conjunto de mecanismos difere entre servicos e nao
  elimina todos os riscos de entrega; validar cada contrato e janela de falha em
  testes de integracao distribuida.

### ADR-002 — Persistencia poliglota com propriedade por servico

- **Status:** Aceito para o estado atual.
- **Decisao:** PostgreSQL e fonte transacional para ordens OS e Billing; MongoDB
  armazena historico OS e agregado operacional Execution. Cada servico controla
  seu proprio banco; referencias a ordem entre servicos sao IDs e APIs/eventos,
  nao foreign keys cruzadas.
- **Motivacao:** constraints/transacoes relacionais para dados financeiros e
  estado de ordem; modelo documental para historico e agregado de execucao com
  listas de eventos/reparos.
- **Consequencias:** sem joins ou transacao atomica entre servicos; consistencia
  eventual e validacao de referencias remotas. Backup e retencao precisam ser
  administrados por banco/servico.

### ADR-003 — HPA adiado; replicas fixas no estado atual

- **Status:** Aceito provisoriamente; revisitar antes de producao.
- **Decisao:** manter o numero de replicas configurado nos Deployments e nao
  declarar HPA ate que metricas, limites e capacidade do ambiente sejam
  dimensionados.
- **Evidencia:** OS declara duas replicas; Billing e Execution uma replica cada.
  Ha requests/limits em Deployments, mas nao foi encontrado `HorizontalPodAutoscaler`.
- **Motivacao:** um HPA sem metrica de utilizacao/objetivo, recursos requests
  consistentes e capacidade de cluster pode gerar escalonamento instavel ou
  insuficiente. `kube-prometheus-stack` fornece observabilidade, mas nao define
  por si so politicas de autoscaling.
- **Consequencias:** nao ha escala horizontal automatica; capacidade e
  disponibilidade ficam limitadas aos replicas fixos. Implementar HPA requer
  metricas alvo, limites min/max, testes de carga e compatibilidade de
  consumidores RabbitMQ.

### ADR-004 — AWS como provedor de nuvem

- **Status:** Implementado operacionalmente — AWS/EKS provisionado e em uso;
  os recursos nao sao gerenciados pelos arquivos Terraform deste repositorio.
- **Decisao:** AWS e o provedor de nuvem adotado e Amazon EKS hospeda os
  workloads Kubernetes. Kind permanece como ambiente local e efemero de
  validacao.
- **Contexto:** o Terraform versionado aqui provisiona Kind. Os workflows dos
  servicos recebem `KUBE_CONFIG` para acessar o cluster externo AWS/EKS. A
  topologia e a configuracao operacional AWS nao estao descritas nos repositorios
  analisados.
- **Alternativas consideradas:** Azure Kubernetes Service, Google Kubernetes
  Engine, Kubernetes autogerenciado em maquinas virtuais e manter apenas Kind.
- **Motivacao:** padronizar o provedor de nuvem conforme decisao do projeto e
  utilizar um servico Kubernetes gerenciado para reduzir a operacao do control
  plane. A escolha de EKS mantem compatibilidade com os manifests Kubernetes e
  com o deploy existente via `kubectl`.
- **Consequencias:** AWS/EKS e o ambiente de deploy adotado; Kind continua
  isolado para validacao local/CI. A manutencao dos recursos AWS e feita fora do
  Terraform deste repositorio. Manter a configuracao operacional, acesso IAM,
  conectividade dos runners, armazenamento, backups e politicas de seguranca
  documentados e controlados no ambiente AWS.
- **Pendencias documentais:** registrar neste ou em repositorio operacional
  autorizado a regiao, VPC/subnets, estrategia de entrada (Ingress/ALB), DNS/TLS,
  storage classes, identidade do GitHub Actions, backups e recuperacao. Esses
  itens nao invalidam o estado implementado de AWS/EKS; sao detalhes de
  topologia/operação nao inferidos a partir do codigo atual.
