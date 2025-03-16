variable "database_subnet_ids" {}
variable "aurora_kms_key_id" {}
variable "rds_sg_id" {}

resource "aws_rds_cluster" "main" {
  cluster_identifier            = "aurora-cluster"
  engine                        = "aurora-postgresql"
  availability_zones            = ["ap-southeast-1a", "ap-southeast-1b"]
  database_name                 = "user_db"
  manage_master_user_password   = true
  master_username               = "test"
  master_user_secret_kms_key_id = var.aurora_kms_key_id
  skip_final_snapshot           = false
  final_snapshot_identifier     = "main-rds-cluster-${replace(timestamp(), ":", "-")}"
  snapshot_identifier           = "has-mock-data"
  backup_retention_period       = 5
  preferred_backup_window       = "07:00-09:00"
  # apply_immediately      = true
  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  storage_encrypted      = true
  vpc_security_group_ids = [var.rds_sg_id]
  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
    ]
  }
}

resource "aws_rds_cluster_instance" "main" {
  count               = 2
  identifier          = "aurora-cluster-${count.index}"
  cluster_identifier  = aws_rds_cluster.main.id
  instance_class      = "db.t4g.medium"
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version
  publicly_accessible = true
}

resource "aws_db_subnet_group" "aurora" {
  name        = "aurora-subnet-group"
  subnet_ids  = var.database_subnet_ids
  description = "Subnet group for Aurora RDS cluster"
}

