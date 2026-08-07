terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.26"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }
}

# 1. ArgoCD Dedicated Namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

# 2. ArgoCD Helm Release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = var.chart_version
  wait       = true
  timeout    = 600

  values = [
    yamlencode({
      crds = {
        install = true
        keep    = true
      }
    })
  ]
  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# 3. ArgoCD Root Application Stack (App-of-Apps)
resource "kubectl_manifest" "argocd_root_application" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bookverse-application-stack
  namespace: ${kubernetes_namespace.argocd.metadata[0].name}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: ${var.repo_url}
    targetRevision: ${var.target_revision}
    path: ${var.app_path}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${kubernetes_namespace.argocd.metadata[0].name}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
YAML

  depends_on = [
    helm_release.argocd,
    var.bookverse_namespace_dependency
  ]
}
