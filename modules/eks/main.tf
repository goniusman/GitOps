# variable "env" { type = string }
# variable "cluster_name" { type = string }
# variable "public_subnet_id" { type = string }
# variable "private_subnet_id" { type = string }
# variable "desired_nodes" { type = number }
# variable "max_nodes" { type = number }
# variable "min_nodes" { type = number }

# IAM Roles
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Control Plane
resource "aws_eks_cluster" "main" {
  name     = "${var.cluster_name}-${var.env}"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = concat(
      var.public_subnet_ids,
      var.private_subnet_ids
    )
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# IAM Role for Nodes
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-group-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# Node Group
resource "aws_eks_node_group" "main_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main-node-group-${var.env}"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids = var.private_subnet_ids
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = var.desired_nodes
    max_size     = var.max_nodes
    min_size     = var.min_nodes
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy
  ]
}

# resource "kubernetes_namespace" "kubernetes_dashboard" {
#   metadata {
#     name = "kubernetes-dashboard"
#   }

#   depends_on = [aws_eks_node_group.main_nodes]
# }


# Bookverse Namespace with Istio injection
# resource "kubernetes_namespace" "bookverse" {
#   metadata {
#     name = "bookverse"
#     labels = {
#       "istio-injection" = "enabled"
#     }
#   }

#   depends_on = [aws_eks_node_group.main_nodes]
# }






# output "cluster_name" { value = aws_eks_cluster.main.name }
# output "cluster_endpoint" { value = aws_eks_cluster.main.endpoint }
# output "cluster_certificate_authority_data" { value = aws_eks_cluster.main.certificate_authority[0].data }
# output "bookverse_namespace" { value = kubernetes_namespace.bookverse.metadata[0].name }
