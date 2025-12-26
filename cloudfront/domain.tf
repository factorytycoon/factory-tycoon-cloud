# ==================================================
# Route 53 Hosted Zone
# ==================================================
resource "aws_route53_zone" "main" {
  name = "factorytycoon.net"
}

# ==================================================
# ACM Certificate for CloudFront (us-east-1)
# ==================================================
resource "aws_acm_certificate" "frontend" {
  provider          = aws.us
  domain_name       = "factorytycoon.net"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.factorytycoon.net"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# ==================================================
# Route 53 Record for ACM DNS Validation
# ==================================================
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.frontend.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# ==================================================
# Wait for ACM Certificate Validation
# ==================================================
resource "aws_acm_certificate_validation" "frontend" {
  provider                = aws.us
  certificate_arn         = aws_acm_certificate.frontend.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}

# ==================================================
# Route 53 Alias Records for CloudFront
# ==================================================
resource "aws_route53_record" "frontend_alias_root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "factorytycoon.net"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "frontend_alias_www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.factorytycoon.net"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
