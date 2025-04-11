resource "aws_rds_cluster" "main" {
  cluster_identifier            = "aurora-cluster"
  engine                        = "aurora-postgresql"
  availability_zones            = ["ap-southeast-1a", "ap-southeast-1b"]
  database_name                 = "user_db" # (optional) name of automatically created database on cluster creation
  manage_master_user_password   = true
  master_username               = "test"
  master_user_secret_kms_key_id = var.aurora_kms_key_id
  skip_final_snapshot           = false
  final_snapshot_identifier     = "main-rds-cluster-${replace(timestamp(), ":", "-")}"
  snapshot_identifier           = "scrooge-bank-prod-v1"
  backup_retention_period       = 5
  preferred_backup_window       = "07:00-09:00"
  # apply_immediately      = true
  db_subnet_group_name   = var.db_subnet_group_name
  storage_encrypted      = true
  vpc_security_group_ids = [var.rds_sg_id]
  # lifecycle {
  #   ignore_changes = [
  #     final_snapshot_identifier,
  #     cluster_identifier,
  #     availability_zones,
  #   ]
  # }
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

resource "aws_db_proxy" "lambdas" {
  name                   = "rds-proxy-for-lambdas"
  debug_logging          = true
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = false
  role_arn               = var.rds_proxy_role_arn
  vpc_security_group_ids = [var.db_proxy_sg_id] # if rds_sg, can connect but instantly disconnect
  vpc_subnet_ids         = var.db_subnet_group_subnet_ids

  auth {
    auth_scheme = "SECRETS"
    description = "Cluster generated master user password"
    iam_auth    = "DISABLED" # disabled makes it more secure
    secret_arn  = aws_rds_cluster.main.master_user_secret[0].secret_arn
  }
}

resource "aws_db_proxy_default_target_group" "lambdas" {
  db_proxy_name = aws_db_proxy.lambdas.name
  connection_pool_config {
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 120
  }
}

resource "aws_db_proxy_target" "lambdas" {
  db_cluster_identifier = aws_rds_cluster.main.id
  db_proxy_name         = aws_db_proxy.lambdas.name
  target_group_name     = aws_db_proxy_default_target_group.lambdas.name
}