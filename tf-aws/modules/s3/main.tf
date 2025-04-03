resource "aws_s3_bucket" "sftp_bucket" {
  bucket = "scrooge-bank-g3t3-monetary-transactions"
}

resource "aws_s3_bucket_notification" "sftp_bucket_notification" {
  bucket = aws_s3_bucket.sftp_bucket.id

  lambda_function {
    lambda_function_arn = var.sftp_lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "monetary_transactions/"
    filter_suffix       = ".json"
  }
}