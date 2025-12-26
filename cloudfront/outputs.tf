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
