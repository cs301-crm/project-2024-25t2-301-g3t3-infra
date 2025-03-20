output "aurora_kms_key_id" {
  value = aws_kms_key.aurora.key_id
}

output "aurora_kms_key_arn" {
  value = aws_kms_key.aurora.arn
}
