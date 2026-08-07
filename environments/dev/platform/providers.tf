terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }
}

variable "use_floci" {
  type    = bool
  default = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = var.use_floci ? "mock_access_key" : null
  secret_key                  = var.use_floci ? "mock_secret_key" : null
  skip_credentials_validation = var.use_floci
  skip_metadata_api_check     = var.use_floci
  skip_requesting_account_id  = var.use_floci

  dynamic "endpoints" {
    for_each = var.use_floci ? [1] : []
    content {
      eks = "http://localhost:4566"
      ssm = "http://localhost:4566"
      sts = "http://localhost:4566"
    }
  }
}

# Read Cluster Name from Layer 1 via SSM
data "aws_ssm_parameter" "cluster_name" {
  name = "/bookverse/dev/cluster_name"
}

data "aws_eks_cluster" "this" {
  name = data.aws_ssm_parameter.cluster_name.value
}

data "aws_eks_cluster_auth" "this" {
  name = data.aws_ssm_parameter.cluster_name.value
}

# Provider Setup (Handles local Floci kubeconfig vs Real AWS EKS Tokens)
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}