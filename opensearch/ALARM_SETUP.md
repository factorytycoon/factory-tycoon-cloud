# OpenSearch 알람 설정 가이드

## 개요

이 문서는 OpenSearch에서 SNS를 통해 Lambda로 알람을 전송하는 시스템을 Terraform으로 구성하는 방법을 설명합니다.

## 아키텍처

```
OpenSearch Monitor → SNS Topic → Lambda (opensearch-to-mariadb) → Backend API → Redis Pub/Sub
```

## Terraform 리소스

### 1. OpenSearch 모듈 (`opensearch/`)

- **IAM Role**: OpenSearch가 SNS에 메시지를 publish할 수 있는 권한
- **IAM Policy**: SNS Topic에 대한 publish 권한

### 2. SNS 모듈 (`sns/`)

- **SNS Topic**: 알람 메시지를 받는 토픽
- **구독 설정**: Lambda 모듈에서 관리 (순환 의존성 방지)

### 3. Lambda 모듈 (`lambda/`)

- **Lambda Function**: `opensearch-to-mariadb` 함수
- **SNS Subscription**: SNS 토픽 구독
- **Lambda Permission**: SNS가 Lambda를 호출할 수 있는 권한

## 배포 순서

```bash
# 1. SNS 토픽 먼저 배포
cd /home/jiminu/code/lgcns-final/factory-tycoon-cloud/sns
terraform init
terraform apply

# 2. OpenSearch 배포 (SNS Role 포함)
cd /home/jiminu/code/lgcns-final/factory-tycoon-cloud/opensearch
terraform init
terraform apply

# 3. Lambda 배포 (SNS 구독 포함)
cd /home/jiminu/code/lgcns-final/factory-tycoon-cloud/lambda
terraform init
terraform apply
```

## OpenSearch Monitor 설정 (수동)

Terraform으로 OpenSearch 인프라를 배포한 후, OpenSearch Dashboard에서 Monitor를 수동으로 설정해야 합니다.

### 1. OpenSearch Dashboard 접속

```bash
# OpenSearch 엔드포인트 확인
terraform output -raw access_url
```

### 2. Monitor 생성

1. OpenSearch Dashboard → Alerting → Monitors → Create monitor
2. Monitor 설정:
   - **Monitor name**: 원하는 이름 입력
   - **Monitor type**: Per query monitor
   - **Schedule**: 모니터링 주기 설정 (예: Every 1 minute)

### 3. Query 정의

```json
{
  "query": {
    "bool": {
      "filter": [
        {
          "range": {
            "@timestamp": {
              "gte": "now-1m",
              "lte": "now"
            }
          }
        }
      ]
    }
  }
}
```

### 4. Trigger 설정

- **Trigger name**: 트리거 이름 입력
- **Severity level**: 심각도 레벨 선택
- **Trigger condition**: 알람 발생 조건 설정

예시:
```
ctx.results[0].hits.total.value > 0
```

### 5. Action 설정

1. **Action name**: 액션 이름 입력
2. **Destination type**: Amazon SNS
3. **SNS topic ARN**: Terraform output에서 확인한 SNS Topic ARN 입력
   ```bash
   cd /home/jiminu/code/lgcns-final/factory-tycoon-cloud/sns
   terraform output -raw sns_topic_arn
   ```
4. **IAM role ARN**: OpenSearch SNS Role ARN 입력
   ```bash
   cd /home/jiminu/code/lgcns-final/factory-tycoon-cloud/opensearch
   terraform output -raw sns_role_arn
   ```

### 6. Message 템플릿

```json
{
  "monitor_name": "{{ctx.monitor.name}}",
  "trigger_name": "{{ctx.trigger.name}}",
  "severity": "{{ctx.trigger.severity}}",
  "period_start": "{{ctx.periodStart}}",
  "period_end": "{{ctx.periodEnd}}",
  "hits": {{ctx.results.0.hits.hits}}
}
```

## 확인 사항

### 1. SNS Topic ARN 확인

```bash
cd /home/jiminu/code/lgcns-final/factory-tycoon-cloud/sns
terraform output sns_topic_arn
```

### 2. OpenSearch SNS Role ARN 확인

```bash
cd /home/jiminu/code/lgcns-final/factory-tycoon-cloud/opensearch
terraform output sns_role_arn
```

### 3. Lambda 함수 ARN 확인

```bash
cd /home/jiminu/code/lgcns-final/factory-tycoon-cloud/lambda
terraform output opensearch_to_mariadb_function_arn
```

### 4. SNS 구독 확인

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn $(cd /home/jiminu/code/lgcns-final/factory-tycoon-cloud/sns && terraform output -raw sns_topic_arn) \
  --region ap-northeast-2
```

## 테스트

### 1. SNS로 테스트 메시지 전송

```bash
aws sns publish \
  --topic-arn $(cd /home/jiminu/code/lgcns-final/factory-tycoon-cloud/sns && terraform output -raw sns_topic_arn) \
  --message '{"monitor_name":"test","trigger_name":"test","hits":[{"_source":{"message":"test"}}]}' \
  --region ap-northeast-2
```

### 2. Lambda 로그 확인

```bash
aws logs tail /aws/lambda/factory-tycoon-opensearch-to-mariadb --follow --region ap-northeast-2
```

## 트러블슈팅

### OpenSearch가 SNS에 메시지를 보낼 수 없는 경우

1. OpenSearch Monitor의 Action에서 IAM Role ARN이 올바른지 확인
2. IAM Role의 신뢰 정책에 `es.amazonaws.com`이 포함되어 있는지 확인
3. IAM Role에 SNS Publish 권한이 있는지 확인

### Lambda가 트리거되지 않는 경우

1. SNS 구독이 제대로 생성되었는지 확인
2. Lambda Permission이 올바르게 설정되었는지 확인
3. Lambda 함수의 VPC 설정 확인

### Lambda 실행 중 오류 발생

1. CloudWatch Logs에서 에러 메시지 확인
2. Lambda 환경 변수 확인 (REDIS_ENDPOINT, BACKEND_API_URL 등)
3. Lambda의 VPC 및 Security Group 설정 확인

## 주의사항

1. **순환 의존성**: SNS 토픽과 Lambda 구독은 Lambda 모듈에서 관리됩니다.
2. **수동 설정**: OpenSearch Monitor는 Dashboard를 통해 수동으로 설정해야 합니다.
3. **IAM 권한**: OpenSearch가 SNS에 메시지를 보내려면 적절한 IAM Role이 필요합니다.
4. **VPC 구성**: Lambda 함수가 VPC 내에서 실행되므로 네트워크 연결을 확인하세요.

## 참고 자료

- [OpenSearch Alerting Documentation](https://opensearch.org/docs/latest/monitoring-plugins/alerting/)
- [AWS SNS Documentation](https://docs.aws.amazon.com/sns/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
