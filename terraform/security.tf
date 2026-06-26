resource "aws_security_group" "k8s_sg" {
  name        = "bookverse-${var.environment}-k8s-sg"
  description = "Network security rules for Bookverse Cluster"
  vpc_id      = aws_vpc.bookverse_vpc.id

  # Allow SSH from anywhere (For demo purposes; protect this in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow K8s Api Traffic (For kubectl local controls)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP access to your NestJS Microservices / ArgoUI via ingress
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inter-node Internal Kubernetes Communication (Flannel / Calico Networking)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Unrestricted outbound access (To download dependencies/Docker hub images)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}