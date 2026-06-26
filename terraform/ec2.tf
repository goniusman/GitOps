# Find latest Ubuntu 22.04 Minimal Image
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "k8s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium" # 2 vCPUs, 4GB RAM - Perfect for running your 7 microservices + Argo
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = var.ssh_key_name

  root_block_device {
    volume_size           = 30 # 30 GB SSD for Docker images and DB volumes
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "bookverse-${var.environment}-master"
    Role        = "k8s-master"
    Environment = var.environment
  }
}

variable "ssh_key_name" {
  type        = string
  description = "The name of your existing pre-uploaded AWS EC2 Key pair"
}







# Existing k8s_master code remains above...

# New Worker Node Provisioning
resource "aws_instance" "k8s_workers" {
  count                  = var.worker_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium" # Worker nodes need RAM/CPU for microservices
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = var.ssh_key_name

  root_block_device {
    volume_size           = 40 # Larger disk space for application Docker images
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "bookverse-${var.environment}-worker-${count.index + 1}"
    Role        = "k8s-worker"
    Environment = var.environment
  }
}

variable "worker_count" {
  type        = number
  description = "Number of Kubernetes worker nodes to provision"
  default     = 2 # Scalable enterprise standard (1 Master, 2 Workers)
}






