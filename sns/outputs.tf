output "topic_name" {
  description = "SNS Topic name"
  value       = aws_sns_topic.events.name
}

output "topic_arn" {
  description = "SNS Topic ARN"
  value       = aws_sns_topic.events.arn
}
