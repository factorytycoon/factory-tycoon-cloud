# Lambda Functions

3개의 Lambda 함수로 구성된 데이터 파이프라인:

## Architecture

```
IoT Core → Lambda1 → ElastiCache (Redis)
                          ↓
                     Lambda2 → MongoDB
                          ↓
                     Lambda3 → OpenSearch
```

## Lambda Functions

### 1. iot-to-cache
- **트리거**: IoT Core Topic Rule
- **역할**: IoT 센서 데이터를 Redis에 저장
- **처리**: 
  - 최신 데이터를 Hash로 저장
  - 시계열 데이터를 Sorted Set에 저장
  - 처리 대기 큐에 추가

### 2. cache-to-mongodb
- **트리거**: EventBridge (2분마다)
- **역할**: Redis 큐의 데이터를 MongoDB에 저장
- **배치**: 최대 1000개씩 처리

### 3. cache-to-opensearch
- **트리거**: iot-to-cache (비동기 Invoke)
- **역할**: Redis 큐의 데이터를 OpenSearch에 저장
- **배치**: 최대 1000개씩 처리

## Deployment

### 1. Python 패키지 준비

각 Lambda 함수는 외부 라이브러리를 사용하므로 Lambda Layer 또는 함수와 함께 패키징 필요:

```bash
# 예: iot-to-cache 함수 패키징
cd lambda/functions/iot-to-cache
pip install -r requirements.txt -t .
cd ../../..
```

### 2. terraform.tfvars 설정

```bash
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 파일 수정
```

필수 변수:
- `redis_endpoint`: ElastiCache 엔드포인트
- `mongodb_uri`: MongoDB 연결 URI
- `opensearch_endpoint`: OpenSearch 엔드포인트

### 3. Terraform 배포

```bash
cd lambda
terraform init -reconfigure
terraform plan
terraform apply
```

## 환경 변수

각 Lambda 함수에 설정되는 환경 변수:

| 변수 | Lambda1 | Lambda2 | Lambda3 |
|------|---------|---------|---------|
| REDIS_ENDPOINT | ✓ | ✓ | ✓ |
| REDIS_PORT | ✓ | ✓ | ✓ |
| MONGODB_URI | - | ✓ | - |
| MONGODB_DB | - | ✓ | - |
| OPENSEARCH_ENDPOINT | - | - | ✓ |

## 주의사항

1. **VPC 설정**: Lambda가 ElastiCache와 통신하려면 같은 VPC의 private subnet에 있어야 합니다.

2. **보안 그룹**: ElastiCache와 OpenSearch의 보안 그룹에서 Lambda 보안 그룹의 접근을 허용해야 합니다.

3. **MongoDB URI**: `terraform.tfvars`에서 실제 MongoDB 연결 정보로 수정 필요.

4. **OpenSearch 자격증명**: `cache-to-opensearch/lambda_function.py`의 하드코딩된 자격증명을 환경 변수나 Secrets Manager로 교체 권장.

5. **패키지 크기**: 라이브러리 포함 시 Lambda 크기 제한(250MB)을 초과할 수 있으므로 Lambda Layer 사용 권장.
