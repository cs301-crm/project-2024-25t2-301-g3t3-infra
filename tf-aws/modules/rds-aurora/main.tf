variable "database_subnet_ids" {}
variable "aurora_kms_key_id" {}

resource "aws_rds_cluster" "main" {
  cluster_identifier            = "aurora-cluster"
  engine                        = "aurora-postgresql"
  availability_zones            = ["ap-southeast-1a", "ap-southeast-1b"]
  database_name                 = "user_db"
  manage_master_user_password   = true
  master_username               = "test"
  master_user_secret_kms_key_id = var.aurora_kms_key_id
  skip_final_snapshot           = true
  backup_retention_period       = 0
  # backup_retention_period = 5 # uncomment if skip_final_snapshot is false
  # preferred_backup_window = "07:00-09:00" # uncomment if skip_final_snapshot is false
  apply_immediately    = true
  db_subnet_group_name = aws_db_subnet_group.aurora.name
}

resource "aws_rds_cluster_instance" "main" {
  count               = 2
  identifier          = "aurora-cluster-${count.index}"
  cluster_identifier  = aws_rds_cluster.main.id
  instance_class      = "db.r6i.large"
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version
  publicly_accessible = false
}

resource "aws_db_subnet_group" "aurora" {
  name        = "aurora-subnet-group"
  subnet_ids  = var.database_subnet_ids
  description = "Subnet group for Aurora RDS cluster"
}

