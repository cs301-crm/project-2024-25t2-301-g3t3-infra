module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  billing_mode = "PAY_PER_REQUEST"
  table_name   = "business_transactions_table"
}

module "iam" {
  source = "./modules/iam"
}

module "eks" {
  source = "./modules/eks"
  eks_cluster_role_arn = module.iam.eks_cluster_role_arn
  eks_cluster_role_policy_attachment = module.iam.eks_cluster_role_policy_attachment
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids = module.vpc.public_subnet_ids
  eks_node_role_arn = module.iam.eks_node_role_arn
  eks_node_role_policy_attachments = module.iam.eks_node_role_policy_attachments
}