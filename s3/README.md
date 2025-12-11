# Terraform Backend 설정

S3와 DynamoDB를 사용한 중앙 집중식 Terraform state 관리 인프라입니다.

## 생성 리소스

- **S3 버킷**: Terraform state 파일 저장 (버전 관리, 암호화)
- **DynamoDB 테이블**: State lock (동시 실행 방지)

## 배포 순서 (⚠️ 가장 먼저 실행)

```bash
cd backend
terraform init
terraform apply
```

배포 후 출력값을 확인하세요:
```bash
terraform output backend_config
```

## 다른 모듈 설정

backend 배포 후, 각 모듈에 backend 설정을 추가하세요:

### VPC 예시
```terraform
# vpc/versions.tf
terraform {
  backend "s3" {
    bucket         = "ft-terraform-state"
    key            = "vpc/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "ft-terraform-lock"
    encrypt        = true
  }
}
```

### ElastiCache에서 VPC state 읽기
```terraform
# elasticache/data.tf
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "ft-terraform-state"
    key    = "vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# 사용
vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
```

## 마이그레이션 방법

기존 로컬 state를 S3로 이동:

```bash
cd vpc

# 1. backend 설정 추가 (versions.tf)
# 2. 초기화 및 마이그레이션
terraform init -migrate-state

# yes 입력하면 자동으로 S3로 복사됨
```

## 주의사항

- 이 모듈은 **가장 먼저 배포**해야 합니다
- S3 버킷 이름은 **전 세계에서 고유**해야 합니다
- DynamoDB는 PAY_PER_REQUEST (거의 무료)
- State 파일은 민감 정보 포함 → S3 암호화 활성화됨
