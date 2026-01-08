resource "aws_sns_topic" "events" {
  name              = var.topic_name
  kms_master_key_id = var.kms_master_key_id

  tags = var.tags
}

# SNS Topic Subscription for OpenSearch to MariaDB Lambda
resource "aws_sns_topic_subscription" "opensearch_to_mariadb" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "lambda"
  endpoint  = data.terraform_remote_state.lambda.outputs.opensearch_to_mariadb_function_arn
}

# IAM role for OpenSearch Notifications to publish to SNS
resource "aws_iam_role" "opensearch_notifications_role" {
  name = "${var.topic_name}-notifications-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "es.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "opensearch_notifications_publish" {
  name = "${var.topic_name}-notifications-publish"
  role = aws_iam_role.opensearch_notifications_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["sns:Publish"],
        Resource = aws_sns_topic.events.arn
      }
    ]
  })
}
