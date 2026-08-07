variable "enabled" {
  type    = bool
  default = false # Set to true when you want to enable it later
}

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  namespace        = "kube-system"
  create_namespace = false
  version          = "3.12.0"

  # Tells Helm to forcibly overwrite existing unmanaged cluster resources
  force_update     = true
  recreate_pods    = true

  # Re-enable serviceAccount and rbac creation with adoption settings
  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
}