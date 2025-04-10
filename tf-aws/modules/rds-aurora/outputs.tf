output "rds_cluster_arn" {
  value = aws_rds_cluster.main.arn
}

output "rds_cluster_endpoint" {
  value = aws_rds_cluster.main.endpoint
}

output "rds_cluster_secret_arn" {
  value = aws_rds_cluster.main.master_user_secret[0].secret_arn
}

output "db_proxy_lambdas_endpoint" {
  value = aws_db_proxy.lambdas.endpoint
}