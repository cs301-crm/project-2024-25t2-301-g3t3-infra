variable "az" {}
variable "region" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.16"
    }
  }
  required_version = ">= 1.0"
  backend "s3" {
    bucket = "scrooge-bank-g3t3-terraform-state"
    key    = "global/main.tfstate"
    region = "ap-southeast-1" # cannot use variable because this is used before variables are declared
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
  az       = var.az
}

module "iam" {
  source                 = "./modules/iam"
  sftp_bucket_arn        = module.s3.sftp_bucket_arn
  user_aurora_arn        = module.rds-aurora.user_aurora_arn
  aurora_kms_key_arn     = module.kms.aurora_kms_key_arn
  user_aurora_secret_arn = module.rds-aurora.user_aurora_secret_arn
}

module "kms" {
  source = "./modules/kms"
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  billing_mode = "PAY_PER_REQUEST"
  table_name   = "business_transactions_table"
}

module "rds-aurora" {
  source              = "./modules/rds-aurora"
  database_subnet_ids = module.vpc.database_subnet_ids
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

module "lambda_process_monetary_transactions" {
  source                                        = "./modules/lambda_process_monetary_transactions"
  process_monetary_transactions_lambda_role_arn = module.iam.process_monetary_transactions_lambda_role_arn
  sftp_bucket_arn                               = module.s3.sftp_bucket_arn
  database_subnet_ids                           = module.vpc.database_subnet_ids
  lambda_sg_id                                  = module.vpc.lambda_sg_id
  user_aurora_secret_arn                        = module.rds-aurora.user_aurora_secret_arn
}

module "bastion_ec2" {
  source           = "./modules/bastion_ec2"
  public_subnet_id = module.vpc.public_subnet_id
  bastion_sg       = module.vpc.bastion_sg_id
}