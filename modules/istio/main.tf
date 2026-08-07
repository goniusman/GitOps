terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.26" }
    helm       = { source = "hashicorp/helm", version = "~> 2.12" }
    kubectl    = { source = "alekc/kubectl", version = "~> 2.0" }
  }
}

resource "kubernetes_namespace" "istio_system" {
  metadata { name = "istio-system" }
}

# 1. Istio Base (CRDs)
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.20.0"
}

# 2. Istiod (Control Plane)
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.20.0"

  depends_on = [helm_release.istio_base]
}

# 3. Istio Ingress Gateway
resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.20.0"

  depends_on = [helm_release.istiod]
}