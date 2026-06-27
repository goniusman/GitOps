terraform {
  required_providers {
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = "0.6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# 1. Spin up Minikube (Optimized for a 4-Core / 12GB RAM Host)
resource "minikube_cluster" "my_cluster" {
  driver       = "docker" 
  cluster_name = "minikube"
  cpus         = 4          # Leaves 1 core for your host OS
  memory       = "12288mb"   # Leaves 4GB RAM for your host OS
  addons       = ["ingress", "dashboard", "metrics-server", "storage-provisioner"]
}

# 2. Dynamic Provider Configurations
provider "kubernetes" {
  host                   = minikube_cluster.my_cluster.host
  client_certificate     = minikube_cluster.my_cluster.client_certificate
  client_key             = minikube_cluster.my_cluster.client_key
  cluster_ca_certificate = minikube_cluster.my_cluster.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = minikube_cluster.my_cluster.host
    client_certificate     = minikube_cluster.my_cluster.client_certificate
    client_key             = minikube_cluster.my_cluster.client_key
    cluster_ca_certificate = minikube_cluster.my_cluster.cluster_ca_certificate
  }
}

provider "kubectl" {
  host                   = minikube_cluster.my_cluster.host
  client_certificate     = minikube_cluster.my_cluster.client_certificate
  client_key             = minikube_cluster.my_cluster.client_key
  cluster_ca_certificate = minikube_cluster.my_cluster.cluster_ca_certificate
  load_config_file       = false
}

# 3. Deploy Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata { name = "argocd" }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "9.5.14"
}

# 4. Storage Infrastructure (Persistent Volumes)
# resource "kubernetes_persistent_volume" "prometheus_pv" {
#   metadata { name = "prometheus-pv" }
#   spec {
#     capacity           = { storage = "5Gi" }
#     access_modes       = ["ReadWriteOnce"]
#     storage_class_name = "manual"
#     persistent_volume_source {
#       host_path {
#         path = "/mnt/data/prometheus"
#       }
#     }
#   }
# }

# resource "kubernetes_persistent_volume" "grafana_pv" {
#   metadata { name = "grafana-pv" }
#   spec {
#     capacity           = { storage = "3Gi" }
#     access_modes       = ["ReadWriteOnce"]
#     storage_class_name = "manual"
#     persistent_volume_source {
#       host_path {
#         path = "/mnt/data/grafana"
#       }
#     }
#   }
# }

# 5. Bootstrap GitOps Application Stack via kubectl_manifest
resource "kubectl_manifest" "argocd_root_application" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bookverse-application-stack
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/goniusman/GitOps.git
    targetRevision: master
    path: helm/argocd-apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML

  depends_on = [helm_release.argocd, minikube_cluster.my_cluster]
}













