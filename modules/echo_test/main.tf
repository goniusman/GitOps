
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.26"
    }
  }
}

variable "bookverse_namespace" { type = string }

resource "kubernetes_namespace" "test_app" {
  metadata { name = "test-app" }
}

resource "kubernetes_deployment" "echo_test" {
  metadata {
    name      = "echo-test"
    namespace = kubernetes_namespace.test_app.metadata[0].name
  }

  spec {
    replicas = 2
    selector { match_labels = { app = "echo-test" } }

    template {
      metadata { labels = { app = "echo-test" } }
      spec {
        container {
          name  = "echo-server"
          image = "registry.k8s.io/e2e-test-images/agnhost:2.39"
          args  = ["netexec", "--http-port=8080"]

          port { container_port = 8080 }

          resources {
            limits   = { cpu = "100m", memory = "128Mi" }
            requests = { cpu = "50m", memory = "64Mi" }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "echo_test_svc" {
  metadata {
    name      = "echo-test-svc"
    namespace = kubernetes_namespace.test_app.metadata[0].name
  }

  spec {
    selector = { app = "echo-test" }
    port {
      port        = 80
      target_port = 8080
    }
    type = "ClusterIP"
  }
}
