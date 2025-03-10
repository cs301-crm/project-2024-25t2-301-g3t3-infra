output "bucket_name" {
  value = aws_s3_bucket.transaction_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.transaction_bucket.arn
}