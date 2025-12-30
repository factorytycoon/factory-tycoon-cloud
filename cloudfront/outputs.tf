output "cloudfront_domain" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.this.id
}

output "route53_zone_name_servers" {
  description = "Name servers for the Route 53 hosted zone. These must be manually updated in the registered domain settings."
  value       = aws_route53_zone.main.name_servers
}

output "alb_dns_name_resolved" {
  description = "ALB DNS name used for the CloudFront backend origin (auto-discovered unless overridden by var.alb_dns_name)."
  value       = local.alb_dns_name
}

output "alb_discovery_candidate_lb_arns" {
  description = "Candidate Load Balancer ARNs discovered by tag lookup (debug helper)."
  value       = try(local.factory_ingress_lb_arns, [])
}
