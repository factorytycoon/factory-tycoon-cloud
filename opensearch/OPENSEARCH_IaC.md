# OpenSearch Monitoring & Alerting - Terraform IaC

Factory Tycoon 생산 공정의 OpenSearch 모니터링을 Terraform으로 완벽히 관리하는 Infrastructure as Code 구현입니다.

## 📊 개요

세 가지 생산 공정(Inspection, Painting, Turning)의 센서 데이터를 OpenSearch에서 모니터링하고, 상태에 따라 자동으로 알람을 발송합니다.

- **자동화된 모니터링**: 1분 주기로 각 공정의 최신 센서 데이터 조회
- **점수 기반 알람**: 센서 값을 점수로 변환하여 Green → Yellow → Orange → Red 4단계로 판별
- **Terraform 관리**: 모든 설정(Query, Monitor, Trigger)을 코드로 관리

## 🏗️ 구조

```
opensearch/
├── versions.tf           # Terraform 및 Provider 설정
├── providers.tf          # AWS & OpenSearch Provider 설정
├── main.tf              # OpenSearch 도메인 및 IAM Role 정의
├── monitors.tf          # 3개 공정의 Monitor 정의
├── triggers.tf          # Trigger 조건 로직 (변수 + 스크립트 참조)
├── variables.tf         # 모든 변수 정의
├── outputs.tf           # Output 정의
├── data.tf              # 원격 상태 데이터 소스
├── README.md            # 이 파일
└── trigger_scripts/     # Trigger 조건 스크립트 (Groovy)
    ├── inspection_yellow.js
    ├── inspection_orange.js
    ├── inspection_red.js
    ├── painting_yellow.js
    ├── painting_orange.js
    ├── painting_red.js
    ├── turning_yellow.js
    ├── turning_orange.js
    └── turning_red.js
```

## 📋 모니터링 공정

### 1️⃣ Inspection (검수) - ft-pi-004

**센서 값**: Weight (무게), Torque (토크)

| 상태 | 조건 | Weight | Torque |
|------|------|--------|--------|
| Green | ≤5점 | 1000~1100g | <30 or >55 |
| Yellow | 6점 | 400~999 / 1101~1700g | 30~45 |
| Orange | 7~9점 | 400~999 / 1101~1700g | 46~55 |
| Red | ≥10점 | <400 / >1700g | <5 / >55 |

### 2️⃣ Painting (도색) - ft-pi-003

**센서 값**: VOC (유해가스), Pressure (분사압력), Temperature (온도)

| 상태 | 조건 | VOC | Pressure | Temperature |
|------|------|-----|----------|-------------|
| Green | ≤5점 | <50 | 3.8~4.2 | 42~48°C |
| Yellow | 6점 | 50~149 | 3.5~3.7 / 4.3~4.8 | 38~41 / 49~55°C |
| Orange | 7~9점 | 150~499 | 3.5~4.8 (Red 제외) | <38 / >55 (Red 제외)°C |
| Red | ≥10점 | >500 | <1.0 / >7.0 | >80°C |

### 3️⃣ Turning (선삭) - ft-pi-002

**센서 값**: RPM (회전수), Noise (소음), Displacement (변위)

| 상태 | 조건 | RPM | Noise | Displacement |
|------|------|-----|-------|--------------|
| Green | ≤5점 | 3000~2900 | <99 / >115 | <0.21 / >1.0 |
| Yellow | 6점 | 2700~2899 | 99~105 | 0.21~0.50 |
| Orange | 7~9점 | 2400~2699 / >3300 | 106~114 | 0.51~1.00 |
| Red | ≥10점 | <500 | >115 | >1.00 |

## 🚀 배포 절차

### 1단계: 필수 모듈 먼저 배포

```bash
# VPC, Security Groups, SNS, Lambda 먼저 배포
cd /path/to/vpc && terraform apply
cd /path/to/security-groups && terraform apply
cd /path/to/sns && terraform apply
cd /path/to/lambda && terraform apply
```

### 2단계: OpenSearch 배포

```bash
cd /home/jiminu/code/lgcns-final/factory-tycoon-cloud/opensearch

# Terraform 초기화
terraform init

# Plan 확인
terraform plan

# 배포
terraform apply
```

### 3단계: 사전 구성 확인

배포 후 다음을 확인하세요:

```bash
# Monitor IDs 확인
terraform output inspection_monitor_id
terraform output painting_monitor_id
terraform output turning_monitor_id

# SNS Topic ARN 확인
terraform output sns_topic_arn

# OpenSearch 접속 URL
terraform output dashboard_url

# 마스터 사용자 정보 (TF State 파일에서 확인)
terraform output master_user_name
terraform output -json | jq '.master_user_password'
```

## ⚙️ 수동 설정 (OpenSearch Dashboard)

Terraform으로 관리되는 부분:
- ✅ OpenSearch 도메인
- ✅ IAM Role/Policy (SNS 권한)
- ✅ Monitor (Query 정의)
- ✅ Trigger 조건 로직 (스크립트)

**아직 수동 설정이 필요한 부분**:
- ⚠️ Trigger 생성 및 SNS Action 연결
  - OpenSearch Dashboard → Alerting → Monitors
  - Monitor 선택 후 Trigger 추가
  - Action에서 SNS Topic 및 Role ARN 지정

## 📝 변수 커스터마이징

`terraform.tfvars`에서 임계값을 조정할 수 있습니다:

```hcl
# Inspection 공정 임계값 수정
inspection_config = {
  weight_red_low     = 400
  weight_red_high    = 1700
  torque_red_low     = 5
  torque_red_high    = 55
  # ... 기타 값
}

# Alert 레벨 수정
alert_thresholds = {
  yellow_min = 6
  yellow_max = 6
  orange_min = 7
  orange_max = 9
  red_min    = 10
}
```

변수 정의는 [variables.tf](variables.tf)를 참고하세요.

## 📊 Alert Flow

```
OpenSearch Monitor (1분 주기)
    ↓
Sensor Data Query (최신 1개 데이터)
    ↓
Trigger Condition (점수 계산 로직)
    ↓
Alert Level 판별 (Yellow/Orange/Red)
    ↓
SNS Topic 발행
    ↓
Lambda (opensearch-to-mariadb)
    ↓
Backend API
    ↓
Redis Pub/Sub
    ↓
Frontend (실시간 알림)
```

## 🔧 Trigger 스크립트 구조

모든 Trigger 스크립트는 동일한 패턴을 따릅니다:

```groovy
// 1. 데이터 검증
if (ctx.results[0].hits.total.value == 0) {
    return false;  // 데이터 없으면 알람 안 함
}

// 2. 센서 데이터 파싱
for (def hit : ctx.results[0].hits.hits) {
    def sensors = hit._source.sensors;
    def sensor_value = sensors[0].value;
    
    // 3. 점수 계산
    int score = calculateScore(sensor_value);
    
    // 4. 알람 레벨 판별
    if (score >= threshold) {
        return true;  // 알람 발동
    }
}

return false;
```

## 📈 점수 계산 예시 (Inspection)

```
Weight = 600g, Torque = 40
↓
Weight 점수 = 2 (Yellow 범위)
Torque 점수 = 2 (Yellow 범위)
Phot 점수 = 1 (기본값)
↓
Total = 2 + 2 + 1 = 5점 (Green)
```

```
Weight = 600g, Torque = 50
↓
Weight 점수 = 2 (Yellow 범위)
Torque 점수 = 4 (Orange 범위)
Phot 점수 = 1 (기본값)
↓
Total = 2 + 4 + 1 = 7점 (Orange)
```

## 🔐 보안

- OpenSearch 마스터 사용자 인증 활성화
- HTTPS/TLS 암호화 (Policy-Min-TLS-1-2-2019-07)
- 전송 중 암호화 및 저장 시 암호화
- VPC 내부 전용 접근

## 🐛 트러블슈팅

### OpenSearch Provider 연결 실패

```bash
# OpenSearch 도메인이 준비될 때까지 대기 필요
# domain_endpoint 출력값으로 직접 접속 확인
curl -u user:password https://<endpoint>
```

### Monitor가 생성되었지만 Trigger가 없음

Terraform으로는 Monitor만 생성되며, Trigger는 OpenSearch Dashboard에서 수동 추가 필요:

1. OpenSearch Dashboard 접속
2. Alerting → Monitors → 생성된 Monitor 선택
3. Add trigger → 조건/액션 설정

### SNS 구독 확인

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn <sns_topic_arn> \
  --region ap-northeast-2
```

## 📚 참고 자료

- [OpenSearch Alerting Docs](https://opensearch.org/docs/latest/monitoring-plugins/alerting/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [OpenSearch Terraform Provider](https://registry.terraform.io/providers/opensearch-project/opensearch/latest)

## 📝 라이선스

Factory Tycoon Project

## 📧 관리자

lgcns5team
