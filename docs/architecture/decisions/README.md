# RFCs e ADRs

RFCs registram alternativas/decisoes que ainda requerem avaliacao. ADRs registram
decisoes permanentes ou o estado arquitetural que os repositorios implementam.
`Aceito` significa aceito para o escopo atual do projeto; nao substitui revisao
para producao.

## RFCs

### RFC-001 — Provedor e topologia Kubernetes

- **Status:** Aberto — provedor de producao nao selecionado.
- **Contexto:** `terraform/main.tf` cria cluster Kind local, adequado a teste
  efemero. Os workflows dos tres servicos fazem deploy para cluster externo
  recebido por `KUBE_CONFIG`. Nenhum provider cloud, VPC, Ingress, DNS, TLS,
  backup ou configuracao de runner com conectividade privada e definido.
- **Alternativas:** manter cluster Kubernetes proprio; adotar Kubernetes
  gerenciado (por exemplo EKS, AKS ou GKE); manter Kind somente para CI e escolher
  posteriormente um ambiente gerenciado.
- **Recomendacao para avaliacao:** manter Kind como ambiente efemero de validacao
  e escolher um servico Kubernetes gerenciado antes do primeiro deploy
  produtivo. Comparar custo, regiao/latencia, disponibilidade, identidade do
  runner, armazenamento persistente, backups, observabilidade e experiencia
  operacional. Nao assumir AWS, Azure ou GCP ate aprovacao explicita.
- **Consequencias:** atualmente o ambiente de CI nao e ambiente produtivo e o
  deploy automatizado depende de cluster, acesso de rede e `KUBE_CONFIG`
  provisionados externamente.
- **Decisao pendente:** provedor, regiao, estrategia de rede/entrada, storage
  classes, HA, backup e gerenciamento de segredos.

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
