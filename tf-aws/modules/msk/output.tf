output "zookeeper_connect_string" {
    value = aws_msk_cluster.scrooge_bank_cluster.zookeeper_connect_string
}

output "msk_bootstrap_brokers" {
  description = "Bootstrap brokers for MSK cluster"
  value       = aws_msk_cluster.scrooge_bank_cluster.bootstrap_brokers
}

output "msk_cluster_arn" {
  value = aws_msk_cluster.scrooge_bank_cluster.arn
}