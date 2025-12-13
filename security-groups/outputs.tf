output "common_sg_id" {
  description = "공통 보안 그룹 ID (VPC 내부 통신용)"
  value       = aws_security_group.common.id
}

output "public_sg_id" {
  description = "공개 리소스용 보안 그룹 ID"
  value       = aws_security_group.public.id
}

output "data_sg_id" {
  description = "데이터 계층용 보안 그룹 ID"
  value       = aws_security_group.data.id
}

output "security_groups" {
  description = "모든 보안 그룹 정보"
  value = {
    common = {
      id   = aws_security_group.common.id
      name = aws_security_group.common.name
    }
    public = {
      id   = aws_security_group.public.id
      name = aws_security_group.public.name
    }
    data = {
      id   = aws_security_group.data.id
      name = aws_security_group.data.name
    }
  }
}
