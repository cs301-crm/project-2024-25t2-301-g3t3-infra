output "sftp_server_endpoint" {
  value = aws_transfer_server.sftp_server.endpoint
}

output "sftp_bucket_arn" {
  value = aws_s3_bucket.sftp_bucket.arn
}