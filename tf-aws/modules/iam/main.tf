variable "sftp_bucket_arn" {}
variable "user_aurora_arn" {}
variable "aurora_kms_key_arn" {}
variable "user_aurora_secret_arn" {}

# IAM for Transfer Family user
resource "aws_iam_role" "sftp_user_role" {
  name = "sftp_user_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "sftp_user_policy" {
  name = "sftp_user_policy"
  role = aws_iam_role.sftp_user_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          var.sftp_bucket_arn,
          "${var.sftp_bucket_arn}/*"
        ]
      }
    ]
  })
}

# IAM for writing into user table in RDS
resource "aws_iam_role" "process_monetary_transactions_lambda_role" {
  name = "process_monetary_transactions_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "process_monetary_transactions_lambda_policy" {
  name = "process_monetary_transactions_lambda_policy"
  role = aws_iam_role.process_monetary_transactions_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.sftp_bucket_arn,
          "${var.sftp_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect",
        ]
        Resource = [
          "${var.user_aurora_arn}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = var.aurora_kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.user_aurora_secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
  role       = aws_iam_role.process_monetary_transactions_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}