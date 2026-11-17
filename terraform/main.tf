resource "kind_cluster" "tech_challenge" {
  name       = var.cluster_name
  node_image = var.kubernetes_node_image

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    node {
      role = "worker"
    }

    node {
      role = "worker"
    }
  }
}

locals {
  namespaces = toset([
    "os-service",
    "billing-service",
    "execution-service",
    "messaging",
    "observability",
  ])
}

resource "kubernetes_namespace_v1" "platform" {
  for_each = local.namespaces

  metadata {
    name = each.value
    labels = {
      "app.kubernetes.io/part-of" = "tech-challenge"
    }
  }
}

resource "random_password" "os_database" {
  length  = 32
  special = false
}

resource "random_password" "os_history_database" {
  length  = 32
  special = false
}

resource "random_password" "os_history_root" {
  length  = 32
  special = false
}

resource "random_password" "billing_database" {
  length  = 32
  special = false
}

resource "random_password" "execution_database" {
  length  = 32
  special = false
}

resource "random_password" "execution_root" {
  length  = 32
  special = false
}

resource "random_password" "rabbitmq" {
  length  = 32
  special = false
}

resource "random_password" "grafana_admin" {
  length  = 32
  special = false
}

resource "helm_release" "os_database" {
  name       = "os-postgresql"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "16.7.27"
  namespace  = "os-service"

  values = [yamlencode({
    auth = {
      username = "os_service"
      password = random_password.os_database.result
      database = "os_service"
    }
    primary = {
      persistence = {
        enabled = true
        size    = var.postgresql_storage_size
      }
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          memory = "512Mi"
        }
      }
    }
  })]

  depends_on = [kubernetes_namespace_v1.platform]
}

resource "helm_release" "billing_database" {
  name       = "billing-postgresql"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "16.7.27"
  namespace  = "billing-service"

  values = [yamlencode({
    auth = {
      username = "billing_service"
      password = random_password.billing_database.result
      database = "billing_service"
    }
    primary = {
      persistence = {
        enabled = true
        size    = var.postgresql_storage_size
      }
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          memory = "512Mi"
        }
      }
    }
  })]

  depends_on = [kubernetes_namespace_v1.platform]
}

resource "helm_release" "os_history_database" {
  name       = "os-mongodb"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "mongodb"
  version    = "16.5.26"
  namespace  = "os-service"

  values = [yamlencode({
    architecture = "standalone"
    auth = {
      enabled      = true
      rootUser     = "root"
      rootPassword = random_password.os_history_root.result
      usernames    = ["os_service"]
      passwords    = [random_password.os_history_database.result]
      databases    = ["os_service_history"]
    }
    persistence = {
      enabled = true
      size    = var.mongodb_storage_size
    }
    resources = {
      requests = {
        cpu    = "100m"
        memory = "256Mi"
      }
      limits = {
        memory = "768Mi"
      }
    }
  })]

  depends_on = [kubernetes_namespace_v1.platform]
}

resource "helm_release" "execution_database" {
  name       = "execution-mongodb"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "mongodb"
  version    = "16.5.26"
  namespace  = "execution-service"

  values = [yamlencode({
    architecture = "standalone"
    auth = {
      enabled      = true
      rootUser     = "root"
      rootPassword = random_password.execution_root.result
      usernames    = ["execution_service"]
      passwords    = [random_password.execution_database.result]
      databases    = ["execution_service"]
    }
    persistence = {
      enabled = true
      size    = var.mongodb_storage_size
    }
    resources = {
      requests = {
        cpu    = "100m"
        memory = "256Mi"
      }
      limits = {
        memory = "768Mi"
      }
    }
  })]

  depends_on = [kubernetes_namespace_v1.platform]
}

resource "helm_release" "rabbitmq" {
  name       = "rabbitmq"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "rabbitmq"
  version    = "15.0.0"
  namespace  = "messaging"

  values = [yamlencode({
    auth = {
      username = "tech_challenge"
      password = random_password.rabbitmq.result
    }
    persistence = {
      enabled = true
      size    = "2Gi"
    }
    resources = {
      requests = {
        cpu    = "100m"
        memory = "256Mi"
      }
      limits = {
        memory = "768Mi"
      }
    }
  })]

  depends_on = [kubernetes_namespace_v1.platform]
}

resource "kubernetes_secret_v1" "rabbitmq_credentials" {
  for_each = toset(["os-service", "billing-service", "execution-service"])

  metadata {
    name      = "rabbitmq-credentials"
    namespace = each.value
  }

  data = {
    username = "tech_challenge"
    password = random_password.rabbitmq.result
  }
  type = "Opaque"

  depends_on = [helm_release.rabbitmq, kubernetes_namespace_v1.platform]
}

resource "helm_release" "monitoring" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "70.0.0"
  namespace  = "observability"

  values = [yamlencode({
    grafana = {
      enabled       = true
      adminPassword = random_password.grafana_admin.result
      persistence = {
        enabled = true
        size    = "1Gi"
      }
    }
    prometheus = {
      prometheusSpec = {
        retention = "7d"
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              resources = {
                requests = {
                  storage = "5Gi"
                }
              }
            }
          }
        }
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
      }
    }
  })]

  depends_on = [kubernetes_namespace_v1.platform]
}
