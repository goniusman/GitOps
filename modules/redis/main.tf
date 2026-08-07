terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "env" {
  type    = string
  default = "dev"
}
variable "use_floci" {
  type        = bool
  default     = true
  description = "Skip ElastiCache provisioning when running in Floci"
}

# Only create AWS ElastiCache resources if NOT using Floci
resource "aws_elasticache_subnet_group" "this" {
  count      = var.use_floci ? 0 : 1
  name       = "bookverse-${var.env}-redis-subnet"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "redis" {
  name   = "bookverse-${var.env}-redis-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_elasticache_cluster" "this" {
  count                = var.use_floci ? 0 : 1
  cluster_id           = "bookverse-${var.env}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this[0].name
  security_group_ids   = [aws_security_group.redis.id]
}

# Output dynamic endpoint depending on Floci vs AWS
output "redis_endpoint" {
  value = var.use_floci ? "localhost:6379" : aws_elasticache_cluster.this[0].cache_nodes[0].address
}
