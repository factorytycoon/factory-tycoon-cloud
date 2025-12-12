# ==========================================
# EC2 Instance (Public Subnet)
# ==========================================

# 1. Security Group - EC2 접근 제어
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # SSH 접근
  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # 8080 포트
  ingress {
    description = "Application port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 8081 포트
  ingress {
    description = "Application port 8081"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 아웃바운드 허용
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ec2-sg"
    }
  )
}

# 2. EC2 Instance
resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Public Subnet에 배치 (첫 번째 Public Subnet 사용)
  subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = var.instance_name
    }
  )
}
