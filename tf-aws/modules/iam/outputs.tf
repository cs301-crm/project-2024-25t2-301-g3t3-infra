output "sftp_user_role_arn" {
  value = aws_iam_role.sftp_user_role.arn
}

output "process_monetary_transactions_lambda_role_arn" {
  value = aws_iam_role.process_monetary_transactions_lambda_role.arn 
}