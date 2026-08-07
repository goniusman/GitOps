variable "bookverse_namespace_dependency" {
  type        = any
  description = "Explicit dependency on the Bookverse namespace creation"
}

variable "argocd_namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace where ArgoCD will be installed"
}

variable "chart_version" {
  type        = string
  default     = "6.7.18"
  description = "ArgoCD Helm chart version"
}

variable "repo_url" {
  type        = string
  default     = "https://github.com/goniusman/GitOps.git"
  description = "Git repository containing the GitOps manifests"
}

variable "target_revision" {
  type        = string
  default     = "main"
  description = "Git branch, tag, or commit hash to track"
}

variable "app_path" {
  type        = string
  default     = "helm/argocd-apps"
  description = "Subpath within the repository containing ArgoCD root manifests"
}