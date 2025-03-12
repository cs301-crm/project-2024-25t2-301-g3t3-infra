output "sftp_bucket_name" {
  value = aws_s3_bucket.sftp_bucket.bucket
}

output "sftp_bucket_arn" {
  value = aws_s3_bucket.sftp_bucket.arn
}