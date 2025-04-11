resource "aws_docdb_cluster" "default" {
  cluster_identifier = "scrooge-bank-cluster"
  engine                  = "docdb"
  availability_zones = var.vpc_azs
  master_username    = "test"
  master_password    = "notrealpassword"
  db_subnet_group_name = var.db_subnet_group_name
  engine_version = "5.0.0"

  skip_final_snapshot           = true
#   skip_final_snapshot           = false
#   final_snapshot_identifier     = "main-docdb-cluster-${replace(timestamp(), ":", "-")}"
#   snapshot_identifier           = "has-mock-data"
#   backup_retention_period       = 5
#   preferred_backup_window       = "07:00-09:00"
  storage_encrypted = true
  storage_type = "standard"
  vpc_security_group_ids = [var.docdb_sg_id]

  tags = {
    "Name" = "scrooge-bank-docdb"
  }
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 2
  identifier         = "scrooge-bank-cluster-${count.index}"
  cluster_identifier = aws_docdb_cluster.default.id
  instance_class     = "db.t4g.medium"
}
