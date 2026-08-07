terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "use_floci" {
  type        = bool
  default     = true
  description = "Set to true when running locally with Floci, false for real AWS"
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
  s3_use_path_style           = var.use_floci

  dynamic "endpoints" {
    for_each = var.use_floci ? [1] : []
    content {
      ec2            = "http://localhost:4566"
      s3             = "http://localhost:4566"
      rds            = "http://localhost:4566"
      iam            = "http://localhost:4566"
      sts            = "http://localhost:4566"
      eks            = "http://localhost:4566"
      ssm            = "http://localhost:4566"
    }
  }
}