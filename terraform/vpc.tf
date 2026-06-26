# Create the isolated network
resource "aws_vpc" "bookverse_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "bookverse-${var.environment}-vpc"
    Environment = var.environment
  }
}

# Internet Gateway for Public Traffic
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.bookverse_vpc.id
  tags   = { Name = "bookverse-${var.environment}-igw" }
}

# Public Subnet (For Load Balancers / Bastions)
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.bookverse_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags              = { Name = "bookverse-${var.environment}-public-1" }
}

# Private Subnet (Where your 7 microservices & DB actually live)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.bookverse_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "bookverse-${var.environment}-private-1" }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# NAT Gateway allowing Private Subnet to securely connect outward
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id
  tags          = { Name = "bookverse-${var.environment}-nat" }
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.bookverse_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.bookverse_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}