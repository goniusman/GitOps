terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.26"
    }
  }
}


resource "kubernetes_namespace" "bookverse" {
  metadata {
    name = "bookverse"

    labels = {
      istio-injection = "enabled"
    }
  }
}

output "bookverse_namespace" {
  value = kubernetes_namespace.bookverse.metadata[0].name
}