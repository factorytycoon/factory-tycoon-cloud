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
