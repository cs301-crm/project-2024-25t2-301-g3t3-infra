resource "null_resource" "create_dummy_zip" {
  provisioner "local-exec" {
    command = "echo 'This is a dummy file' > dummy.txt && zip dummy.zip dummy.txt"
  }
}

resource "aws_lambda_function" "process_monetary_transactions" {
  function_name = "process_monetary_transactions"
  role          = var.process_monetary_transactions_lambda_role_arn
  handler       = "process_monetary_transactions.lambda_handler"
  runtime       = "python3.13"
  filename      = "dummy.zip" # Dummy file, the actual zip file will be uploaded in the lambda repo
  timeout       = 60
  environment {
    variables = {
      DB_SECRET_ARN = var.user_aurora_secret_arn
    }
  }
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  depends_on = [null_resource.create_dummy_zip]
}

resource "aws_lambda_permission" "s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_monetary_transactions.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.sftp_bucket_arn
}