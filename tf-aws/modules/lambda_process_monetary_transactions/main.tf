terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    klayers = {
      source  = "ldcorentin/klayer"
      version = "~> 1.0.0"
    }
  }
}
data "archive_file" "dummy_zip" {
  type = "zip"
  source_file = "process-mt.py"
  output_path = "process-mt.zip"
}

data "klayers_package_latest_version" "psycopg" {
  name           = "psycopg"
  region         = "ap-southeast-1"
  python_version = "3.12"
}


resource "aws_lambda_function" "process_mt" {
  function_name    = "process-mt-lambda"
  role             = var.process_monetary_transactions_lambda_role_arn 
  handler          = "process-mt.handler"
  runtime          = "python3.12"
  filename         = "process-mt.zip" # Dummy file, the actual zip file will be uploaded in the lambda repo
  source_code_hash = data.archive_file.dummy_zip.output_base64sha256
  timeout          = 60
  environment {
    variables = {
      PROXY_HOST = var.db_proxy_lambdas_endpoint
      DB_PORT = "5432"
      DB_NAME = "user_db"
      DB_SECRET_ARN = var.rds_cluster_secret_arn
    }
  }
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  layers = [data.klayers_package_latest_version.psycopg.arn]
  tags = {
    Name = "process-mt-lambda"
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.mt_queue_arn
  function_name    = aws_lambda_function.process_mt.arn
  batch_size       = 5
  enabled          = true

  depends_on = [
    aws_lambda_permission.sqs_trigger
  ]
}

resource "aws_lambda_permission" "sqs_trigger" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_mt.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = var.mt_queue_arn
} 

