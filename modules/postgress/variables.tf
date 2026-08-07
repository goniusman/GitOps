variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for DB Subnet Group"
}

variable "node_security_group_id" {
  type        = string
  description = "Security Group ID of the EKS worker nodes"
}