output "user_aurora_arn" {
  value = aws_rds_cluster.main.arn
}

output "user_aurora_endpoint" {
  value = aws_rds_cluster.main.endpoint
}

output "user_aurora_secret_arn" {
  value = aws_rds_cluster.main.master_user_secret[0].secret_arn
}