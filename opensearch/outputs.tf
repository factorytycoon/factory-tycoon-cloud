output "domain_id" {
  description = "OpenSearch 도메인 ID"
  value       = aws_opensearch_domain.main.domain_id
}

output "domain_arn" {
  description = "OpenSearch 도메인 ARN"
  value       = aws_opensearch_domain.main.arn
}

output "endpoint" {
  description = "OpenSearch 도메인 엔드포인트"
  value       = aws_opensearch_domain.main.endpoint
}

output "dashboard_endpoint" {
  description = "OpenSearch Dashboards 엔드포인트"
  value       = aws_opensearch_domain.main.dashboard_endpoint
}

output "access_url" {
  description = "OpenSearch 접속 URL"
  value       = "https://${aws_opensearch_domain.main.endpoint}"
}

output "dashboard_url" {
  description = "OpenSearch Dashboards 접속 URL"
  value       = "https://${aws_opensearch_domain.main.endpoint}/_dashboards"
}

output "master_user_name" {
  description = "OpenSearch 마스터 사용자 이름"
  value       = var.master_user_name
}

output "master_user_password" {
  description = "OpenSearch 마스터 사용자 패스워드"
  value       = var.master_user_password
  sensitive   = true
}

output "sns_role_arn" {
  description = "OpenSearch SNS IAM Role ARN"
  value       = aws_iam_role.opensearch_sns_role.arn
}

# ============================================================================
# Monitor Outputs
# ============================================================================

output "inspection_monitor_id" {
  description = "Inspection Process Monitor ID"
  value       = opensearch_monitor.inspection.monitor_id
}

output "inspection_monitor_name" {
  description = "Inspection Process Monitor Name"
  value       = opensearch_monitor.inspection.name
}

output "painting_monitor_id" {
  description = "Painting Process Monitor ID"
  value       = opensearch_monitor.painting.monitor_id
}

output "painting_monitor_name" {
  description = "Painting Process Monitor Name"
  value       = opensearch_monitor.painting.name
}

output "turning_monitor_id" {
  description = "Turning Process Monitor ID"
  value       = opensearch_monitor.turning.monitor_id
}

output "turning_monitor_name" {
  description = "Turning Process Monitor Name"
  value       = opensearch_monitor.turning.name
}

# ============================================================================
# Alert Configuration Outputs
# ============================================================================

output "alert_thresholds" {
  description = "Alert severity thresholds (score-based)"
  value       = var.alert_thresholds
}

output "inspection_config" {
  description = "Inspection process sensor configuration"
  value       = var.inspection_config
  sensitive   = false
}

output "painting_config" {
  description = "Painting process sensor configuration"
  value       = var.painting_config
  sensitive   = false
}

output "turning_config" {
  description = "Turning process sensor configuration"
  value       = var.turning_config
  sensitive   = false
}

output "trigger_scripts_location" {
  description = "Location of trigger condition scripts"
  value       = "${path.module}/trigger_scripts"
}

# ============================================================================
# SNS Integration Outputs
# ============================================================================

output "sns_topic_arn" {
  description = "SNS Topic ARN for alerts (if configured)"
  value       = local.sns_topic_arn
}

output "lambda_function_arn" {
  description = "Lambda Function ARN for processing alerts (if configured)"
  value       = local.lambda_function_arn
}
