output "sftp_server_endpoint" {
  value = data.aws_vpc_endpoint.vpce_tf.dns_entry[0]["dns_name"]
}

output "sftp_bucket_arn" {
  value = aws_s3_bucket.sftp_bucket.arn
}

output "sftp_bucket_name" {
  value = aws_s3_bucket.sftp_bucket.bucket
}