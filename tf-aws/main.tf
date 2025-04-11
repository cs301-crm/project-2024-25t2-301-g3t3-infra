module "vpc" {
  source                     = "./modules/vpc"
  vpc_cidr                   = "10.0.0.0/16"
  pc_mt_id                   = module.mock-server.pc_mt_id
  vpc_mock_server_cidr_block = module.mock-server.vpc_mock_server_cidr_block
}

module "iam" {
  source                 = "./modules/iam"
  sftp_bucket_arn        = module.transfer_family.sftp_bucket_arn
  rds_cluster_arn        = module.rds-aurora.rds_cluster_arn
  aurora_kms_key_arn     = module.kms.aurora_kms_key_arn
  rds_cluster_secret_arn = module.rds-aurora.rds_cluster_secret_arn
  eks_cluster_name       = module.eks.eks_cluster_name
  msk_cluster_arn        = module.msk.msk_cluster_arn
  mt_queue_arn           = module.sqs.mt_queue_arn
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
  source                     = "./modules/rds-aurora"
  database_subnet_ids        = module.vpc.private_subnet_ids
  aurora_kms_key_id          = module.kms.aurora_kms_key_id
  rds_sg_id                  = module.vpc.rds_sg_id
  rds_proxy_role_arn         = module.iam.rds_proxy_role_arn
  db_subnet_group_name       = module.vpc.db_subnet_group_name
  db_subnet_group_subnet_ids = module.vpc.db_subnet_group_subnet_ids
  db_proxy_sg_id             = module.vpc.db_proxy_sg_id
}

module "transfer_family" {
  source                            = "./modules/transfer_family"
  transfer_logging_role_arn         = module.iam.transfer_logging_role_arn
  transfer_s3_role_arn              = module.iam.transfer_s3_role_arn
  vpc_id                            = module.vpc.vpc_id
  private_subnet_ids                = module.vpc.private_subnet_ids
  tf_sg_id                          = module.vpc.tf_sg_id
  external_server_transfer_role_arn = module.iam.external_server_transfer_role_arn
  mt_queue_arn                      = module.sqs.mt_queue_arn
}

module "lambda_process_monetary_transactions" {
  source                                        = "./modules/lambda_process_monetary_transactions"
  process_monetary_transactions_lambda_role_arn = module.iam.process_monetary_transactions_lambda_role_arn
  sftp_bucket_arn                               = module.transfer_family.sftp_bucket_arn
  private_subnet_ids                            = module.vpc.private_subnet_ids
  lambda_sg_id                                  = module.vpc.lambda_sg_id
  rds_cluster_secret_arn                        = module.rds-aurora.rds_cluster_secret_arn
  mt_queue_arn                                  = module.sqs.mt_queue_arn
  db_proxy_lambdas_endpoint                     = module.rds-aurora.db_proxy_lambdas_endpoint
}

module "bastion_ec2" {
  source                        = "./modules/bastion_ec2"
  public_subnet_id              = module.vpc.public_subnet_ids[0]
  bastion_sg                    = module.vpc.bastion_sg_id
  bastion_iam_instance_profile  = module.iam.bastion_msk_profile_name
  msk_cluster_bootstrap_brokers = module.msk.msk_bootstrap_brokers
}

module "msk" {
  source         = "./modules/msk"
  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr
}


module "sqs" {
  source          = "./modules/sqs"
  sftp_bucket_arn = module.transfer_family.sftp_bucket_arn
}

module "mock-server" {
  source                   = "./modules/mock-server"
  crm_vpc_id               = module.vpc.vpc_id
  crm_sftp_server_endpoint = module.transfer_family.sftp_server_endpoint
  crm_vpc_cidr             = module.vpc.vpc_cidr
}

module "amplify" {
  source                   = "./modules/amplify"
  amplify_logging_role_arn = module.iam.amplify_logging_role_arn
}