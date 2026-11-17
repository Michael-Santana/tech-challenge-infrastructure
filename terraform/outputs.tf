output "cluster_name" {
  description = "Name of the Kind cluster."
  value       = kind_cluster.tech_challenge.name
}

output "database_endpoints" {
  description = "In-cluster database service names; each database is isolated in its service namespace."
  value = {
    os_service         = "os-postgresql.os-service.svc.cluster.local:5432"
    os_service_history = "os-mongodb.os-service.svc.cluster.local:27017"
    billing_service    = "billing-postgresql.billing-service.svc.cluster.local:5432"
    execution_service  = "execution-mongodb.execution-service.svc.cluster.local:27017"
  }
}

output "rabbitmq_endpoint" {
  description = "In-cluster AMQP endpoint for service event integration."
  value       = "rabbitmq.messaging.svc.cluster.local:5672"
}

output "grafana_endpoint" {
  description = "In-cluster Grafana endpoint."
  value       = "monitoring-grafana.observability.svc.cluster.local"
}

output "generated_credentials" {
  description = "Generated local-development credentials. Terraform state contains these values; do not commit or share the state."
  sensitive   = true
  value = {
    os_database         = random_password.os_database.result
    os_history_database = random_password.os_history_database.result
    os_history_root     = random_password.os_history_root.result
    billing_database    = random_password.billing_database.result
    execution_database  = random_password.execution_database.result
    execution_root      = random_password.execution_root.result
    rabbitmq            = random_password.rabbitmq.result
    grafana_admin       = random_password.grafana_admin.result
  }
}
