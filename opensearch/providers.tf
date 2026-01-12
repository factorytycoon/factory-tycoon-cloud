provider "aws" {
  region = var.region
}
provider "opensearch" {
  url            = "https://${aws_opensearch_domain.main.endpoint}"
  aws_region     = var.region
  aws_assume_role_arn = ""  # 필요시 설정

  # 초기 배포 시에는 마스터 사용자 인증 사용
  # 이후 SAML/OIDC 등으로 교체 가능
  username = var.master_user_name
  password = var.master_user_password

  insecure = false
  skip_ssl_verification = false
  
  depends_on = [
    aws_opensearch_domain.main,
    aws_opensearch_domain.main.access_policies
  ]
}