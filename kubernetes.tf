provider "aws" {
  region = "us-east-2"
}

# VPC
resource "aws_vpc" "lanchoneteFIAP" {
  id = "vpc-0a9be4e1860b4a006"
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "lanchoneteFIAP-vpc"
  }
}

# Subnet A
resource "aws_subnet" "subnetA" {
  id = "subnet-058d5839f28fa3c6e"
  vpc_id = aws_vpc.lanchoneteFIAP.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "lanchoneteFIAP-subnetA"
  }
}

# Subnet B
resource "aws_subnet" "subnetB" {
  id = "subnet-0cc7b890158d04759"
  vpc_id = aws_vpc.lanchoneteFIAP.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "lanchoneteFIAP-subnetB"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  id = "igw-0ff11bd6d27a24d18"
  vpc_id = aws_vpc.lanchoneteFIAP.id

  tags = {
    Name = "lanchoneteFIAP-igw"
  }
}

# Route Table
resource "aws_route_table" "rt" {
  id = "rtb-00ab6a9c30dfc245e"
  vpc_id = aws_vpc.lanchoneteFIAP.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "lanchoneteFIAP-rt"
  }
}

# Security Group for EKS
resource "aws_security_group" "eks_sg" {
  vpc_id = aws_vpc.lanchoneteFIAP.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lanchoneteFIAP-eks-sg"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "lanchoneteFIAP"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids         = [aws_subnet.subnetA.id, aws_subnet.subnetB.id]
    security_group_ids = [aws_security_group.eks_sg.id]
  }
}

# IAM Role for EKS
resource "aws_iam_role" "eks_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eks_cluster_policy" {
  role = aws_iam_role.eks_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:*",
        "elasticloadbalancing:*",
        "ecr:*",
        "eks:*",
        "cloudwatch:*"
      ]
      Resource = "*"
    }]
  })
}

# EKS Node Group
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name = aws_eks_cluster.eks.name
  node_role    = aws_iam_role.eks_node_role.arn
  subnet_ids   = [aws_subnet.subnetA.id, aws_subnet.subnetB.id]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  instance_types = ["t3.small"]
  ami_type       = "AL2_x86_64"
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}