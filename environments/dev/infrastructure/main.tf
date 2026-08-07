# ------------------------------------------------------------------------------
# Layer 1: Infrastructure Deployment (dev)
# ------------------------------------------------------------------------------

# 1. VPC, Subnets, Internet Gateway, NAT Gateway
module "vpc" {
  source = "../../../modules/vpc"

  env                 = "dev"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.10.0/24"
}

# 2. EKS Cluster & IAM Roles
module "eks" {
  source = "../../../modules/eks"

  env          = "dev"
  cluster_name = "bookverse-dev-cluster"

  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  desired_nodes = 2
  min_nodes     = 2
  max_nodes     = 4
}

# 3. Amazon ECR Repositories
module "ecr" {
  source = "../../../modules/ecr"

  repo_name = "bookverse-api-dev"
}

# 4. S3 Storage Bucket
module "s3" {
  source = "../../../modules/s3"

  bucket_name = "bookverse-dev-assets-bucket"
}

# 5. RDS PostgreSQL Database
module "postgress" {
  source = "../../../modules/postgress"

  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  node_security_group_id = module.eks.node_security_group_id
}

# 6. Redis ElastiCache
module "redis" {
  source = "../../../modules/redis"

  env                = "dev"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  use_floci          = var.use_floci
}

# ------------------------------------------------------------------------------
# SSM Outputs for Layer 2 Consumption (Decouples Terraform States)
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "cluster_name" {
  name  = "/bookverse/dev/cluster_name"
  type  = "String"
  value = module.eks.cluster_name
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "/bookverse/dev/vpc_id"
  type  = "String"
  value = module.vpc.vpc_id
}
