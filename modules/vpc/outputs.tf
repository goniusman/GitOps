# Expose VPC ID
# output "vpc_id" {
#   description = "The ID of the VPC"
#   value       = aws_vpc.main.id # Or whatever your aws_vpc resource name is
# }

# Expose Private Subnet IDs as a list
# output "private_subnets" {
#   value       =  [aws_subnet.private_1.id] # Adjust "aws_subnet.private" to match your resource name
#   value = [aws_subnet.private_1.id]
# }

# Expose Public Subnet IDs as a list
# output "public_subnet_id" { 
#   value = aws_subnet.public_1.id
# }

# # Expose Private Subnet IDs as a list
# output "private_subnet_id" { 
#   description = "List of private subnet IDs"
#   value = aws_subnet.private_1.id
# }

# output "public_subnet_ids" {
#   value = aws_subnet.public[*].id
# }

# output "private_subnet_ids" {
#   value = aws_subnet.private[*].id
# }


output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_1.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_1.id]
}

