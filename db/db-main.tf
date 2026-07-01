# db/main.tf

# 1. Create a dedicated database namespace
resource "kubernetes_namespace" "db" {
  metadata {
    name = "db"
    labels = {
      "istio-injection" = "enabled" # Keeps it consistent with your bookverse setup if needed
    }
  }
}

# 2. Minimal PostgreSQL Deployment
resource "helm_release" "postgresql" {
  name       = "postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "18.7.9"
  namespace  = kubernetes_namespace.db.metadata[0].name
  
  # Crucial: Wait for database pods to be 100% ready before letting Terraform finish
  wait             = true
  wait_for_jobs    = true
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 900


  # Minimal configurations for Minikube footprint
  set {
    name  = "architecture"
    value = "standalone" # Disables complex primary/read-replica pools
  }

  # set {
  #   name  = "image.registry"
  #   value = "docker.io"
  # }

  # set {
  #   name  = "image.repository"
  #   value = "bitnami/postgresql"
  # }

  set {
    name  = "auth.database"
    value = "bookverse_auth"
  }

  set {
    name  = "auth.username"
    value = "bookverse"
  }

  set {
    name  = "auth.password"
    value = "bookverse"
  }

  # Scale down resource requests to the bare minimum
  set {
    name  = "primary.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "primary.resources.requests.memory"
    value = "256Mi"
  }
  set {
    name  = "primary.resources.limits.memory"
    value = "512Mi"
  }

  # Request a tiny slice of local disk space from minikube storage-provisioner
  set {
    name  = "primary.persistence.size"
    value = "1Gi"
  }

  # Turn off sidecar metrics monitoring to save CPU cycles
  set {
    name  = "metrics.enabled"
    value = "false"
  }
}

# 3. Minimal MongoDB Deployment
resource "helm_release" "mongodb" {
  name       = "mongodb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"
  version    = "19.1.16"
  namespace  = kubernetes_namespace.db.metadata[0].name
  
  wait             = true
  wait_for_jobs    = true
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 900

  set {
    name  = "image.registry"
    value = "docker.io"
  }

  # set {
  #   name  = "image.repository"
  #   value = "bitnami/mongodb"
  # }

  # set {
  #   name  = "architecture"
  #   value = "standalone"
  # }

  set {
    name  = "auth.enabled"
    value = "false"
  }

  # NOTE: All auth.databases, usernames, and passwords blocks have been removed.
  # Your apps (Books, Review, Orders) can just connect to their respective 
  # database names directly, and Mongo will create them on the fly!

  # Minimal resource profile
  set {
    name  = "useStatefulSet"
    value = "true"
  }
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "resources.requests.memory"
    value = "256Mi"
  }
  set {
    name  = "resources.limits.memory"
    value = "512Mi"
  }
  set {
    name  = "persistence.size"
    value = "1Gi"
  }
  set {
    name  = "metrics.enabled"
    value = "false"
  }
}