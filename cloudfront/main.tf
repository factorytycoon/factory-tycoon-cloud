resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "factory-tycoon-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200"
  web_acl_id          = aws_wafv2_web_acl.cloudfront_waf.arn

  aliases = [
    "factorytycoon.net",
    "www.factorytycoon.net"
  ]

  # ====================== 
  # ORIGINS
  # ====================== 

  # S3 (Frontend)
  origin {
    domain_name              = data.aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # ALB (Backend)
  origin {
    domain_name = local.alb_dns_name
    origin_id   = "alb-backend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"   # ← 중요
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # ====================== 
  # ORDERED CACHE BEHAVIOR
  # ====================== 

  # API
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "alb-backend"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
      "PUT",
      "POST",
      "PATCH",
      "DELETE"
    ]

    cached_methods = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = [
        "Authorization",
        "Content-Type",
        "Host",
        "Origin",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers"
        ]
      cookies {
        forward = "all"
      }
    }
  }

  # GLB API
  ordered_cache_behavior {
    path_pattern           = "/aws/*"
    target_origin_id       = "alb-backend"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
      "PUT",
      "POST",
      "PATCH",
      "DELETE"
    ]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = [
        "Authorization",
        "Content-Type",
        "Host",
        "Origin",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers"
            ]
      cookies {
        forward = "all"
      }
    }
  }
  
  ordered_cache_behavior {
  path_pattern           = "/ws"
  target_origin_id       = "alb-backend"
  viewer_protocol_policy = "redirect-to-https"
  allowed_methods        = ["GET", "HEAD", "OPTIONS"]
  cached_methods         = ["GET", "HEAD"]
  forwarded_values {
    query_string = true
    headers      = ["Authorization", "Content-Type", "Host", "Origin"]
    cookies {
      forward = "none"
    }
  }
  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 0
}

    # WebSocket
    ordered_cache_behavior {
      path_pattern           = "/ws/*"
      target_origin_id       = "alb-backend"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]

      forwarded_values {
        query_string = true
        headers      = ["Authorization", "Content-Type", "Host", "Origin"]
        cookies {
          forward = "none"
        }
      }

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0
    }

  # ====================== 
  # DEFAULT (Frontend SPA)
  # ====================== 

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # ====================== 
  # SPA FALLBACK
  # ====================== 

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.frontend.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  lifecycle {
    precondition {
      condition     = local.alb_dns_name != null && local.alb_dns_name != ""
      error_message = "Could not resolve ALB DNS name. Discovered ${length(local.factory_ingress_lb_arns)} matching LB(s) for ingress ${var.ingress_namespace}/${var.ingress_name}. If 0, wait until Ingress provisions an ALB (or tags mismatch). If >1, delete leftover LBs or set `alb_dns_name` explicitly (e.g., in `cloudfront/terraform.tfvars`)."
    }
  }
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = data.aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${data.aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      }
    ]
  })
}
