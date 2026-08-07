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
  }
}



#  Create dedicated Namespace
resource "kubernetes_namespace" "dashboard" {
  metadata {
    name = "kubernetes-dashboard"
  }
}


# Helm chart installs the dashboard stack AND manages namespace creation
resource "helm_release" "kubernetes_dashboard" {
  name       = "kubernetes-dashboard"
  repository = "https://kubernetes-retired.github.io/dashboard"
  chart      = "kubernetes-dashboard"
  version    = "7.14.0"

  namespace        = "kubernetes-dashboard"
  create_namespace = true

  values = [
    yamlencode({
      auth = {
        skip = true
      }
      api = {
        dashboardOptions = {
          readOnly = false
        }
        containers = {
          args = [
            "--enable-skip-login",
            "--enable-insecure-login"
          ]
        }
      }
    })
  ]
}

# 1. Admin Service Account
resource "kubernetes_service_account" "admin_user" {
  metadata {
    name      = "admin-user"
    namespace = "kubernetes-dashboard"
  }
  depends_on = [helm_release.kubernetes_dashboard]
}

# 2. RBAC Binding
resource "kubernetes_cluster_role_binding" "admin_user" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.admin_user.metadata[0].name
    namespace = "kubernetes-dashboard"
  }
}

# 3. Create a ServiceAccount Token Secret (K8s compatible)
resource "kubernetes_secret" "admin_user_token" {
  metadata {
    name      = "admin-user-token"
    namespace = "kubernetes-dashboard"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.admin_user.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"

  depends_on = [kubernetes_service_account.admin_user]
}

# 4. Fetch the generated token data
data "kubernetes_secret" "admin_user_token" {
  metadata {
    name      = kubernetes_secret.admin_user_token.metadata[0].name
    namespace = "kubernetes-dashboard"
  }

  depends_on = [kubernetes_secret.admin_user_token]
}

# Grant cluster-admin to the default dashboard service account (for Skip login)
resource "kubernetes_cluster_role_binding" "dashboard_skip_admin" {
  metadata {
    name = "dashboard-skip-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "kubernetes-dashboard-web"
    namespace = "kubernetes-dashboard"
  }

  depends_on = [helm_release.kubernetes_dashboard]
}





