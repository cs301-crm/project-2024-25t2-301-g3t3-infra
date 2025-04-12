output "mt_queue_arn" {
  value = aws_sqs_queue.mt_queue.arn
}

output "mt_dlq_queue_arn" {
  value = aws_sqs_queue.mt_queue_deadletter.arn
}