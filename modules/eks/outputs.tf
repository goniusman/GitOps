# output "node_security_group_id" {
#   description = "Security Group ID attached to EKS cluster"
#   value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id # Adjust 'main' to match your aws_eks_cluster resource name
# }

# output "node_security_group_id" {
#   description = "Security Group ID attached to EKS worker nodes"
#   value       = aws_security_group.<YOUR_ACTUAL_SG_NAME>.id
# }


output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "node_security_group_id" {
  value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}


