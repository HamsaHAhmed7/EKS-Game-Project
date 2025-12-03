resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.project}-eks-cluster"
  version  = var.eks_version
  role_arn = var.iam_role_eks

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    endpoint_public_access  = true
    endpoint_private_access = true
    subnet_ids              = var.private_subnets
  }
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.project}-node-group"
  node_role_arn   = var.eks_nodes_role
  subnet_ids      = var.private_subnets

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = var.node_instance_types

  depends_on = [aws_eks_cluster.eks_cluster]
}