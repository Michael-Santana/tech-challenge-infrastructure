variable "cluster_name" {
  description = "Name of the local Kind cluster."
  type        = string
  default     = "tech-challenge"
}

variable "kubernetes_node_image" {
  description = "Kind node image used by the local cluster."
  type        = string
  default     = "kindest/node:v1.31.0"
}

variable "postgresql_storage_size" {
  description = "Persistent volume size for each PostgreSQL service database."
  type        = string
  default     = "2Gi"
}

variable "mongodb_storage_size" {
  description = "Persistent volume size for the execution service database."
  type        = string
  default     = "2Gi"
}
