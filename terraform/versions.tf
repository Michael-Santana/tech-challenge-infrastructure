terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.5.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

provider "kind" {}

provider "kubernetes" {
  host                   = kind_cluster.tech_challenge.endpoint
  client_certificate     = kind_cluster.tech_challenge.client_certificate
  client_key             = kind_cluster.tech_challenge.client_key
  cluster_ca_certificate = kind_cluster.tech_challenge.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.tech_challenge.endpoint
    client_certificate     = kind_cluster.tech_challenge.client_certificate
    client_key             = kind_cluster.tech_challenge.client_key
    cluster_ca_certificate = kind_cluster.tech_challenge.cluster_ca_certificate
  }
}
