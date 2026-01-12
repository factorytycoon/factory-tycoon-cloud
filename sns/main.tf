resource "aws_sns_topic" "events" {
  name              = var.topic_name
  kms_master_key_id = var.kms_master_key_id

  tags = var.tags
}

# Lambda 구독은 Lambda 모듈에서 관리됩니다
# 순환 의존성을 피하기 위해 aws_sns_topic_subscription은 Lambda 모듈에서 생성합니다

# 구독이 필요하면 아래 리소스를 사용하세요.
# resource "aws_sns_topic_subscription" "example" {
#   topic_arn = aws_sns_topic.events.arn
#   protocol  = "email" # or "sqs", "lambda", "https"
#   endpoint  = "example@example.com" # 대상 주소 또는 ARN
# }
