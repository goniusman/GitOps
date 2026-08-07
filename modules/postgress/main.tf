# 1. Subnet Group (Assigns RDS to your private subnets)
resource "aws_db_subnet_group" "postgres" {
  name       = "bookverse-db-subnet-group"
  subnet_ids = var.private_subnet_ids # ✅ Fixed: using input variable

  tags = {
    Name = "Bookverse DB Subnet Group"
  }
}

# 2. Security Group for RDS (Allows incoming traffic from EKS worker nodes)
resource "aws_security_group" "rds_sg" {
  name        = "bookverse-rds-sg"
  description = "Allow inbound traffic from EKS nodes to RDS"
  vpc_id      = var.vpc_id # ✅ Fixed: using input variable

  ingress {
    description     = "PostgreSQL access from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.node_security_group_id] # ✅ Fixed: using input variable
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. RDS Instance
resource "aws_db_instance" "postgres" {
  identifier             = "bookverse-db"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = "db.t3.micro"
  db_name                = "bookversedb"
  username               = "dbadmin"
  password               = "SuperSecretPassword123!"
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
}

# 4. Output the connection endpoint
output "rds_endpoint" {
  value       = aws_db_instance.postgres.endpoint
  description = "Connect your application pods to this endpoint"
}
