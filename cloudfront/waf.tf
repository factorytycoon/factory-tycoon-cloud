# WAF는 CloudFront와 연결하려면 반드시 us-east-1 리전에 만들어야 합니다.
# providers.tf에 정의된 "us" alias provider를 사용합니다.
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider = aws.us

  name        = "factory-tycoon-cloudfront-waf"
  description = "WAF for factory-tycoon CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # AWS 관리형 규칙 추가
  # 1. AWSManagedRulesCommonRuleSet: 일반적인 웹 공격(SQLi, XSS 등)을 차단합니다.
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 10
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "awsCommonRules"
      sampled_requests_enabled   = true
    }
  }

  # 2. AWSManagedRulesAmazonIpReputationList: 악성 IP 주소 목록을 기반으로 차단합니다.
  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 20
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAmazonIpReputationList"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "awsAmazonIpReputation"
      sampled_requests_enabled   = true
    }
  }

  # 3. AWSManagedRulesKnownBadInputsRuleSet: 알려진 악성 입력 패턴을 차단합니다.
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "awsKnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfrontWaf"
    sampled_requests_enabled   = true
  }
}
