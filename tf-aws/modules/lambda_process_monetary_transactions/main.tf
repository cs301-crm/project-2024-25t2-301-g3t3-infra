variable "process_monetary_transactions_lambda_role_arn" {}
variable "lambda_path" {}
variable "sftp_bucket_arn" {}
variable "database_subnet_ids" {}
variable "lambda_sg_id" {}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_path
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "process_monetary_transactions" {
  function_name = "process_monetary_transactions"
  role          = var.process_monetary_transactions_lambda_role_arn
  handler       = "process_monetary_transactions.handler"
  runtime       = "python3.8"
  filename      = data.archive_file.lambda_zip.output_path
  vpc_config {
    subnet_ids         = var.database_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }
}

resource "aws_lambda_permission" "s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_monetary_transactions.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.sftp_bucket_arn
}