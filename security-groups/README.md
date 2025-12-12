# Security Groups Terraform Module

Factory Tycoon 프로젝트의 모든 리소스가 공유하는 중앙 집중식 보안 그룹 모듈입니다.

## 보안 그룹 구성

### 1. Common Security Group (`factory-tycoon-common-sg`)
- **용도**: VPC 내부 리소스 간 통신
- **규칙**: VPC 내부(10.0.0.0/16) 모든 트래픽 허용
- **사용 대상**: 모든 리소스

### 2. Public Security Group (`factory-tycoon-public-sg`)
- **용도**: 외부에서 접근 가능한 리소스
- **규칙**:
  - SSH (22)
  - HTTP (80)
  - HTTPS (443)
  - Application ports (8080, 8081)
- **사용 대상**: EC2, ALB, EKS 노드 등

### 3. Data Security Group (`factory-tycoon-data-sg`)
- **용도**: 데이터 계층 리소스
- **규칙**:
  - Redis (6379) - VPC 내부만
  - HTTPS (443) - VPC 내부만 (OpenSearch)
- **사용 대상**: ElastiCache, OpenSearch, RDS 등

## 사용법

### 1. 보안 그룹 배포

```bash
cd security-groups
terraform init
terraform apply
```

### 2. 다른 모듈에서 사용

각 모듈의 `data.tf`에 추가:

```hcl
data "terraform_remote_state" "security_groups" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state1"
    key    = "security-groups/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
```

`main.tf`에서 보안 그룹 ID 사용:

```hcl
# EC2 예시
resource "aws_instance" "example" {
  # ...
  vpc_security_group_ids = [
    data.terraform_remote_state.security_groups.outputs.common_sg_id,
    data.terraform_remote_state.security_groups.outputs.public_sg_id
  ]
}

# ElastiCache 예시
resource "aws_elasticache_replication_group" "example" {
  # ...
  security_group_ids = [
    data.terraform_remote_state.security_groups.outputs.common_sg_id,
    data.terraform_remote_state.security_groups.outputs.data_sg_id
  ]
}
```

## 배포 순서

1. VPC 모듈
2. **Security Groups 모듈** ← 여기
3. 다른 모듈들 (EC2, EKS, ElastiCache, OpenSearch 등)

## 출력값

- `common_sg_id`: 공통 보안 그룹 ID
- `public_sg_id`: 공개 보안 그룹 ID
- `data_sg_id`: 데이터 보안 그룹 ID
- `security_groups`: 모든 보안 그룹 정보 (ID, Name)

## 주의사항

1. VPC 모듈이 먼저 배포되어 있어야 합니다.
2. 보안 그룹을 변경하면 연결된 모든 리소스에 영향을 줍니다.
3. 실제 운영 환경에서는 SSH 접근을 특정 IP로 제한하는 것을 권장합니다.

## 보안 규칙 수정

보안 규칙을 추가/수정하려면 [main.tf](main.tf)를 편집하고:

```bash
terraform plan
terraform apply
```

변경 사항이 모든 연결된 리소스에 즉시 적용됩니다.
