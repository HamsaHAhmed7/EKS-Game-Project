module "vpc" {
  source  = "./modules/vpc"
  project = var.project
}

module "route53" {
  source         = "./modules/route53"
  domain         = var.domain
  parent_zone_id = var.parent_zone_id
}

module "iam" {
  source = "./modules/iam"
}

module "eks" {
  source              = "./modules/eks"
  project             = var.project
  eks_version         = var.eks_version
  iam_role_eks        = module.iam.eks_cluster_role_arn
  eks_nodes_role      = module.iam.eks_nodes_role_arn
  public_subnets      = module.vpc.public_subnet_ids
  private_subnets     = module.vpc.private_subnet_ids
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
}

module "irsa" {
  source            = "./modules/irsa"
  project           = var.project
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  hosted_zone_id    = module.route53.zone_id
}

module "helm" {
  source                 = "./modules/helm"
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  cert_manager_role_arn  = module.irsa.cert_manager_role_arn
  external_dns_role_arn  = module.irsa.external_dns_role_arn
  domain                 = "eks.${var.domain}"
}