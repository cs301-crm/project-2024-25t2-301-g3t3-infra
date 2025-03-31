module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
}

module "iam" {
  source                 = "./modules/iam"
  sftp_bucket_arn        = module.s3.sftp_bucket_arn
  user_aurora_arn        = module.rds-aurora.user_aurora_arn
  aurora_kms_key_arn     = module.kms.aurora_kms_key_arn
  user_aurora_secret_arn = module.rds-aurora.user_aurora_secret_arn
  eks_cluster_name       = module.eks.eks_cluster_name
}

module "kms" {
  source = "./modules/kms"
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  billing_mode = "PAY_PER_REQUEST"
  table_name   = "business_transactions_table"
}

module "glue" {
  source = "./modules/glue"
}

module "efs" {
  source              = "./modules/efs"
  eks_cluster_sg_id   = module.eks.eks_cluster_sg_id
  private_subnet_1_id = module.vpc.private_subnet_ids[0]
  private_subnet_2_id = module.vpc.private_subnet_ids[1]
}

module "eks" {
  source                             = "./modules/eks"
  eks_cluster_role_arn               = module.iam.eks_cluster_role_arn
  eks_cluster_role_policy_attachment = module.iam.eks_cluster_role_policy_attachment
  private_subnet_ids                 = module.vpc.private_subnet_ids
  public_subnet_ids                  = module.vpc.public_subnet_ids
  eks_node_role_arn                  = module.iam.eks_node_role_arn
  eks_node_role_policy_attachments   = module.iam.eks_node_role_policy_attachments
}

module "helm" {
  source                  = "./modules/helm"
  eks_cluster_name        = module.eks.eks_cluster_name
  eks_private_nodes       = module.eks.eks_private_nodes
  vpc_id                  = module.vpc.vpc_id
  efs_mount_target_zone_a = module.efs.efs_mount_target_zone_a
  efs_mount_target_zone_b = module.efs.efs_mount_target_zone_b
}

module "kubernetes" {
  source             = "./modules/kubernetes"
  efs_file_system_id = module.efs.efs_file_system_id
}

module "rds-aurora" {
  source              = "./modules/rds-aurora"
  database_subnet_ids = module.vpc.private_subnet_ids
  aurora_kms_key_id   = module.kms.aurora_kms_key_id
  rds_sg_id           = module.vpc.rds_sg_id
}

module "s3" {
  source = "./modules/s3"
}

module "transfer_family" {
  source                       = "./modules/transfer_family"
  sftp_user_role_arn           = module.iam.sftp_user_role_arn
  sftp_transaction_bucket_name = module.s3.sftp_bucket_name
}

# module "lambda_process_monetary_transactions" {
#   source                                        = "./modules/lambda_process_monetary_transactions"
#   process_monetary_transactions_lambda_role_arn = module.iam.process_monetary_transactions_lambda_role_arn
#   sftp_bucket_arn                               = module.s3.sftp_bucket_arn
#   private_subnet_ids                            = module.vpc.private_subnet_ids
#   lambda_sg_id                                  = module.vpc.lambda_sg_id
#   user_aurora_secret_arn                        = module.rds-aurora.user_aurora_secret_arn
# }

module "bastion_ec2" {
  source           = "./modules/bastion_ec2"
  public_subnet_id = module.vpc.public_subnet_ids[0]
  bastion_sg       = module.vpc.bastion_sg_id
}