# VPC 내부 통신용 공통 보안 그룹
resource "aws_security_group" "common" {
  name        = "${var.project_name}-common-sg"
  description = "Common security group for all resources in VPC"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # VPC 내부 모든 통신 허용
  ingress {
    description = "Allow all traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-common-sg"
    }
  )
}

# 외부 접근용 보안 그룹 (공개 리소스용)
resource "aws_security_group" "public" {
  name        = "${var.project_name}-public-sg"
  description = "Security group for public-facing resources"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # SSH
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom application ports (8080, 8081)
  ingress {
    description = "Application port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Application port 8081"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-sg"
    }
  )
}

# 데이터베이스/캐시 계층용 보안 그룹
resource "aws_security_group" "data" {
  name        = "${var.project_name}-data-sg"
  description = "Security group for data layer (Redis, OpenSearch, etc.)"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # Redis (6379)
  ingress {
    description = "Redis from VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # OpenSearch/Elasticsearch (443)
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-data-sg"
    }
  )
}
