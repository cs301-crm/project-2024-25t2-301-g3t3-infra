output "zookeeper_connect_string" {
    value = aws_msk_cluster.scrooge_bank_cluster.zookeeper_connect_string
}

# TODO: TLS cert configuration 
# output "bootstrap_brokers_tls" {
#     description = "TLS connection host:port pairs"
#     value = aws_msk_cluster.scrooge_bank_cluster.bootstrap_brokers_tls
# }

output "msk_bootstrap_brokers" {
  description = "Bootstrap brokers for the MSK cluster"
  value       = aws_msk_cluster.scrooge_bank_cluster.bootstrap_brokers
}