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
    null = {
      source  = "hashicorp/null"
      version = "~> 3.3"
    }
  }
}

# 1. Spin up Minikube with required specs and addons
resource "minikube_cluster" "my_cluster" {
  driver       = "docker" # or hyperv for Windows
  cluster_name = "minikube-iac"
  cpus         = "4"
  memory       = "8192mb"
  addons       = ["ingress", "dashboard", "metrics-server"]
}

# Connect providers directly to the cluster attributes
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

# 2. Deploy Argo CD using Helm
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

# --- POSTGRESQL STORAGE ---
resource "kubernetes_persistent_volume" "postgres_pv" {
  metadata { name = "postgres-pv" }
  spec {
    capacity           = { storage = "5Gi" }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "manual"
    persistent_volume_source {
      host_path {
        path = "/mnt/data/postgres"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata { name = "postgres-pvc" }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "manual"
    resources { requests = { storage = "5Gi" } }
    volume_name        = kubernetes_persistent_volume.postgres_pv.metadata[0].name
  }
}

# --- MONGODB STORAGE ---
resource "kubernetes_persistent_volume" "mongodb_pv" {
  metadata { name = "mongodb-pv" }
  spec {
    capacity           = { storage = "10Gi" }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "manual"
    persistent_volume_source {
      host_path {
        path = "/mnt/data/mongodb"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "mongodb_pvc" {
  metadata { name = "mongodb-pvc" }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "manual"
    resources { requests = { storage = "10Gi" } }
    volume_name        = kubernetes_persistent_volume.mongodb_pv.metadata[0].name
  }
}

# --- REDIS STORAGE ---
resource "kubernetes_persistent_volume" "redis_pv" {
  metadata { name = "redis-pv" }
  spec {
    capacity           = { storage = "2Gi" }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "manual"
    persistent_volume_source {
      host_path {
        path = "/mnt/data/redis"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "redis_pvc" {
  metadata { name = "redis-pvc" }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "manual"
    resources { requests = { storage = "2Gi" } }
    volume_name        = kubernetes_persistent_volume.redis_pv.metadata[0].name
  }
}

# 3. Bootstrap Application Infrastructure using Native PowerShell local-exec
resource "null_resource" "bootstrap_argocd_apps" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<EOT
      $manifest = @"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-infrastructure-stack
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/goniusman/GitOps.git'
    targetRevision: master
    path: helm/bookverse/
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: bookverse
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
"@
      $manifest | kubectl apply -f -
    EOT
    interpreter = ["PowerShell", "-Command"]
  }
}