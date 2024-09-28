provider "aws" {
  region = "us-east-2"
}

# VPC
resource "aws_vpc" "lanchoneteFIAP" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "lanchoneteFIAP-vpc"
  }
}

# Security Group for EKS
resource "aws_security_group" "eks_sg" {
  vpc_id = aws_vpc.lanchoneteFIAP.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
  name = "lanchoneteFIAP"
  version = "1.27"
  role_arn = "arn:aws:iam::992382363343:role/techChallenge-FIAP-EksClusterRole-hA8fsjaSWHrh"

  vpc_config {
    subnet_ids         = ["subnet-058d5839f28fa3c6e", "subnet-0cc7b890158d04759"]
    security_group_ids = [aws_security_group.eks_sg.id]
  }
}

# EKS Node Group
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name = aws_eks_cluster.eks.name
  node_role_arn = "arn:aws:iam::992382363343:role/techChallenge-FIAP-EksNodeGroupRole-7l3lSBqPBXCb"
  subnet_ids = ["subnet-058d5839f28fa3c6e", "subnet-0cc7b890158d04759"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  instance_types = ["t3.small"]
  ami_type       = "AL2_x86_64"
}

resource "null_resource" "eks_auth" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl apply -f - <<EOF
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: aws-auth
        namespace: kube-system
      data:
        mapRoles: |
          - rolearn: ${aws_iam_role.eks_admin.arn}
            username: system:node:{{EC2PrivateDNSName}}
            groups:
              - system:bootstrappers
              - system:nodes
        mapUsers: |
          - userarn: arn:aws:iam::992382363343:user/Afonso
            username: admin
            groups:
              - system:masters
      EOF
    EOT
  }

  depends_on = [aws_eks_cluster.eks]
}
