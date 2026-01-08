output "topic_name" {
  description = "SNS Topic name"
  value       = aws_sns_topic.events.name
}

output "topic_arn" {
  description = "SNS Topic ARN"
  value       = aws_sns_topic.events.arn
}

output "opensearch_notifications_role_arn" {
  description = "IAM role ARN for OpenSearch Notifications to publish to SNS"
  value       = aws_iam_role.opensearch_notifications_role.arn
}
