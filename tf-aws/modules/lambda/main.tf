variable process_monetary_transactions_lambda_role_arn {}
variable process_monetary_transactions_lambda_filename {}
variable sftp_bucket_arn {}

resource "aws_lambda_function" "process_monetary_transactions" {
  function_name = "process_monetary_transactions"
  role          = var.process_monetary_transactions_lambda_role_arn
  handler       = "index.handler"
  runtime       = "python3.8"
  filename      = var.process_monetary_transactions_lambda_filename
}

resource "aws_lambda_permission" "s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_monetary_transactions.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.sftp_bucket_arn
}