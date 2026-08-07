# ------------------------------------------------------------------------------
# Layer 2: Platform & Operator Deployment (dev)
# ------------------------------------------------------------------------------

# 1. Kubernetes Namespaces Bootstrap
module "kubernetes_bootstrap" {
  source = "../../../modules/kubernetes_bootstrap"

  providers = {
    kubernetes = kubernetes
  }
}

# 2. Metrics Server
# module "metrics_server" {
#   source = "../../../modules/metrics_server"

#   providers = {
#     helm = helm
#   }

#   depends_on = [
#     module.kubernetes_bootstrap
#   ]
# }

# 3. Istio Service Mesh & Ingress Gateway
module "istio" {
  source = "../../../modules/istio"

  providers = {
    kubernetes = kubernetes
    helm       = helm
    kubectl    = kubectl
  }

  depends_on = [
    module.kubernetes_bootstrap
  ]
}

# 4. Kubernetes Dashboard
module "kubernetes_dashboard" {
  source = "../../../modules/kubernetes_dashboard"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  depends_on = [
    module.kubernetes_bootstrap
  ]
}

# 5. ArgoCD Controller & Root GitOps App
module "argocd" {
  source = "../../../modules/argocd"

  providers = {
    kubernetes = kubernetes
    helm       = helm
    kubectl    = kubectl
  }

  bookverse_namespace_dependency = module.kubernetes_bootstrap.bookverse_namespace

  # Override default Git parameters if needed
  repo_url        = "https://github.com/goniusman/GitOps.git"
  target_revision = "main"
  app_path        = "helm/argocd-apps"

  depends_on = [
    module.kubernetes_bootstrap,
    module.istio
  ]
}

# 6. Verification / Canary Deployment
module "echo_test" {
  source = "../../../modules/echo_test"

  providers = {
    kubernetes = kubernetes
  }

  bookverse_namespace = module.kubernetes_bootstrap.bookverse_namespace

  depends_on = [
    module.argocd
  ]
}