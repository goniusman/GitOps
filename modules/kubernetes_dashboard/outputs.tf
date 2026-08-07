output "dashboard_admin_token" {
  description = "Bearer token to log into Kubernetes Dashboard"
  value       = kubernetes_secret.admin_user_token.data["token"]
  sensitive   = true
}


# terraform output -raw dashboard_admin_token

