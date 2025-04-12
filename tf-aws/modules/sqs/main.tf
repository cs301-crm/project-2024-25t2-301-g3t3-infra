resource "aws_sqs_queue" "mt_queue" {
  name   = "sftp-s3-event-notification-queue"
  policy = data.aws_iam_policy_document.queue.json

  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.mt_queue_deadletter.arn
    maxReceiveCount     = 4
  })
  visibility_timeout_seconds = 120
}

resource "aws_sqs_queue" "mt_queue_deadletter" {
  name = "sftp-s3-event-notification-deadletter-queue"
  policy = data.aws_iam_policy_document.queue.json
}

resource "aws_sqs_queue_redrive_allow_policy" "mt_redrive_allow_policy" {
  queue_url = aws_sqs_queue.mt_queue_deadletter.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.mt_queue.arn]
  })
}


data "aws_iam_policy_document" "queue" { # wtv
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:*:*:sftp-s3-event-notification-queue"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [var.sftp_bucket_arn]
    }
  }
}