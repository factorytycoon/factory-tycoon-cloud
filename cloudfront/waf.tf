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

  # Priority 1: /aws/* 경로의 파일 업로드 요청을 모든 제한 규칙에서 제외
  # 원인: multipart/form-data의 크기 제한(8KB BODY) 때문에 차단됨
  rule {
    name     = "ExemptS3UploadFromSizeRestrictions"
    priority = 1
    action {
      count {}  # 모니터링만 (차단 안 함)
    }
    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string = "/aws"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "STARTS_WITH"
          }
        }
        statement {
          byte_match_statement {
            search_string = "POST"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "exemptS3Upload"
      sampled_requests_enabled   = true
    }
  }

  # Priority 10: 일반적인 웹 공격(SQLi, XSS 등) 차단
  # /aws POST 요청은 제외됨 (위 우선순위 규칙이 count 처리)
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
        
        # 크기 제한 규칙들을 모두 제외 (count 모드로 변경)
        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "SizeRestrictions_QUERYSTRING"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "SizeRestrictions_URIPATH"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "SizeRestrictions_COOKIE_HEADER"
          action_to_use {
            count {}
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "awsCommonRules"
      sampled_requests_enabled   = true
    }
  }

  # Priority 20: 악성 IP 주소 목록 기반 차단
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

  # Priority 30: 알려진 악성 입력 패턴 차단
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
