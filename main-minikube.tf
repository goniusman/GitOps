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

# 1. Spin up Minikube (Cleaned memory format string)
resource "minikube_cluster" "my_cluster" {
  driver       = "docker" 
  cluster_name = "minikube"
  cpus         = 4 
  memory       = "12288" # Clean integer string without "mb"
  addons       = ["ingress", "dashboard", "metrics-server", "storage-provisioner"]
}


# 2. Dynamic Provider Configurations (Plain text strings - no decode needed)
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
  depends_on = [minikube_cluster.my_cluster]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "9.5.14"
}

# NOTE: Section 4 (Static Manual PVs) removed. 
# Your low-resource manifests now rely seamlessly on Minikube's automatic 'standard' StorageClass!

# 4. Bootstrap GitOps Application Stack via kubectl_manifest
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

  depends_on = [helm_release.argocd]
}




# # Manifest 2: Your lightweight Istio telemetry addons
# resource "kubectl_manifest" "istio_addons_application" {
#   yaml_body = <<YAML
# apiVersion: argoproj.io/v1alpha1
# kind: Application
# metadata:
#   name: istio-addons
#   namespace: argocd
# spec:
#   project: default
#   source:
#     repoURL: https://github.com/goniusman/GitOps.git
#     targetRevision: master
#     path: helm/argocd-apps/istio-addons
#   destination:
#     server: https://kubernetes.default.svc
#     namespace: istio-system
#   syncPolicy:
#     automated:
#       prune: true
#       selfHeal: true
# YAML

#   depends_on = [helm_release.argocd]
# }





