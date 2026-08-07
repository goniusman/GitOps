output "namespace" {
  value       = kubernetes_namespace.argocd.metadata[0].name
  description = "The namespace where ArgoCD is deployed"
}

output "root_application_name" {
  value       = kubectl_manifest.argocd_root_application.name
  description = "The name of the root ArgoCD application"
}