# OpenSearch Terraform Module

Factory Tycoon 프로젝트의 OpenSearch 도메인을 관리하는 Terraform 모듈입니다.

## 구성

- **엔진 버전**: OpenSearch 2.11
- **인스턴스**: t3.small.search (1개)
- **스토리지**: 10GB gp3 EBS
- **가용 영역**: 단일 AZ (비용 최적화)
- **네트워크**: VPC Private Subnet
- **보안**: 전송 중 암호화, 저장 시 암호화, 노드 간 암호화
- **인증**: 내부 사용자 데이터베이스

## VPC 구성

이 모듈은 S3 원격 상태에서 VPC 정보를 자동으로 가져옵니다:
- VPC ID
- Private Subnet ID
- VPC CIDR Block

## 사전 요구사항

1. VPC 모듈이 먼저 배포되어야 합니다
2. VPC의 상태가 S3에 저장되어 있어야 합니다

## 사용법

### 1. 초기화

```bash
cd opensearch
terraform init
```

### 2. 계획 확인

```bash
terraform plan
```

### 3. 배포

```bash
terraform apply
```

배포 완료까지 약 15-20분 소요됩니다.

### 4. 접속 정보 확인

```bash
terraform output
```

## 접속 방법

OpenSearch는 Private Subnet에 배포되므로, VPC 내부에서만 접근 가능합니다:

### EC2 인스턴스에서 접속

```bash
# OpenSearch API 엔드포인트
curl -u golden:12345678Qq! https://<opensearch-endpoint>

# OpenSearch Dashboards
# 브라우저에서: https://<opensearch-endpoint>/_dashboards
```

### 로컬에서 접속 (SSH 터널링)

```bash
# EC2를 경유하여 SSH 터널 생성
ssh -i ~/.ssh/mw_key.pem -L 9200:<opensearch-endpoint>:443 ubuntu@<ec2-public-ip>

# 로컬 브라우저에서 접속
# https://localhost:9200/_dashboards
```

## 출력값

- `endpoint`: OpenSearch API 엔드포인트
- `dashboard_endpoint`: OpenSearch Dashboards 엔드포인트
- `access_url`: HTTPS 접속 URL
- `dashboard_url`: Dashboards 접속 URL
- `security_group_id`: OpenSearch 보안 그룹 ID

## 마스터 사용자

- **사용자명**: golden
- **패스워드**: 12345678Qq!

## 비용

약 $25/월 (t3.small.search 1개 + 10GB EBS)

## 주의사항

1. 패스워드는 `terraform.tfvars`에 평문으로 저장됩니다. 실제 운영 환경에서는 AWS Secrets Manager 사용을 권장합니다.
2. OpenSearch 도메인은 삭제 후 재생성 시 같은 이름을 즉시 재사용할 수 없습니다 (약 24시간 대기).
3. Private Subnet에 배포되므로, 외부에서 직접 접근할 수 없습니다.

## 리소스 정리

```bash
terraform destroy
```

도메인 삭제에는 약 10-15분 소요됩니다.
