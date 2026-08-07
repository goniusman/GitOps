module "vpc" {
  source              = "../../modules/vpc"
  env                 = "prod"
  vpc_cidr            = "10.1.0.0/16" # Isolated CIDR for prod
  public_subnet_cidr  = "10.1.1.0/24"
  private_subnet_cidr = "10.1.10.0/24"
}

# module "eks" {
#   source            = "../../modules/eks"
#   env               = "prod"
#   cluster_name      = "my-eks-cluster"
#   public_subnet_id  = module.vpc.public_subnet_id
#   private_subnet_id = module.vpc.private_subnet_id
#   desired_nodes     = 3
#   max_nodes         = 6
#   min_nodes         = 3
# }

module "argocd" {
  source                          = "../../modules/argocd"
  cluster_endpoint                = module.eks.cluster_endpoint
  cluster_ca_certificate          = module.eks.cluster_certificate_authority_data
  cluster_name                    = module.eks.cluster_name
  bookverse_namespace_dependency = module.eks.bookverse_namespace

  depends_on = [module.eks]
}

# Echo test excluded in production or enabled as needed