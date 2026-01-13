resource "aws_sns_topic" "events" {
  name              = var.topic_name
  kms_master_key_id = var.kms_master_key_id

  tags = var.tags
}

# 구독이 필요하면 아래 리소스를 사용하세요.
# resource "aws_sns_topic_subscription" "example" {
#   topic_arn = aws_sns_topic.events.arn
#   protocol  = "email" # or "sqs", "lambda", "https"
#   endpoint  = "example@example.com" # 대상 주소 또는 ARN
# }
