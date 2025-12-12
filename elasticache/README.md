# ElastiCache Redis 모듈

AWS ElastiCache for Redis를 Private Subnet에 배포합니다.

## 아키텍처

```
VPC (10.0.0.0/16)
├── Private Subnet A (10.0.10.0/24) - AZ-2a
│   └── Redis Node 1 (Primary)
└── Private Subnet C (10.0.20.0/24) - AZ-2c
    └── Redis Node 2 (Replica, Multi-AZ)

Security Group: VPC CIDR에서 6379 포트 허용
```

## 포함 리소스

- **Security Group**: Redis 접근 제어 (VPC 내부에서만 6379 포트 허용)
- **Subnet Group**: Private Subnet 2개 (Multi-AZ)
- **Parameter Group**: Redis 7.0 설정
- **Replication Group**: Redis Cluster (Primary + Replica)

## 주요 설정

- **노드 타입**: cache.t3.micro (테스트용, 프로덕션은 t3.small 이상)
- **노드 개수**: 2 (Multi-AZ HA 구성)
- **엔진**: Redis 7.0
- **암호화**: 비활성화 (비용 절감, 필요시 활성화)
- **백업**: 스냅샷 1일 보관, 새벽 3~5시
- **유지보수**: 일요일 오전 5~7시

## 배포 방법

### 1. VPC 정보 확인
```bash
cd ../vpc
terraform output vpc_id
terraform output private_subnets
```

### 2. terraform.tfvars 수정
출력된 VPC ID와 Private Subnet IDs를 `terraform.tfvars`에 입력

### 3. 배포
```bash
cd elasticache
terraform init
terraform plan
terraform apply  # 약 5-10분 소요
```

## 출력값

```bash
terraform output redis_primary_endpoint  # 쓰기/읽기 엔드포인트
terraform output redis_reader_endpoint   # 읽기 전용 (Multi-AZ)
terraform output redis_connection_string # 연결 문자열
terraform output redis_security_group_id # Lambda에 추가할 SG
```

## Lambda/애플리케이션 연결

### Python 예시
```python
import redis

# Primary 엔드포인트 사용 (쓰기/읽기)
r = redis.Redis(
    host='ft-redis.xxxxx.ng.0001.apn2.cache.amazonaws.com',
    port=6379,
    decode_responses=True
)

# 데이터 저장/조회
r.set('sensor:temp', '25.5')
temp = r.get('sensor:temp')
```

### Node.js 예시
```javascript
const redis = require('redis');
const client = redis.createClient({
  socket: {
    host: 'ft-redis.xxxxx.ng.0001.apn2.cache.amazonaws.com',
    port: 6379
  }
});

await client.connect();
await client.set('sensor:temp', '25.5');
const temp = await client.get('sensor:temp');
```

## Security Group 연결

Lambda나 EKS Pod에서 Redis에 접근하려면:

1. **Lambda**: Lambda의 Security Group에 Redis SG로의 아웃바운드 6379 허용
2. **EKS Pod**: Pod의 Security Group에 Redis SG로의 아웃바운드 6379 허용

또는 `allowed_cidr_blocks`에 Lambda/EKS CIDR 추가.

## 비용

- **cache.t3.micro** (2노드): 시간당 ~$0.034 ($0.017 x 2)
- **월 예상 비용**: ~$25 (24시간 가동 시)
- **스냅샷**: 거의 무료 (1일 보관)

## 성능 최적화

프로덕션 환경에서는:
- `cache.t3.small` 이상 사용 (메모리 1.37GB)
- `maxmemory-policy` 설정 (`allkeys-lru` 추천)
- 암호화 활성화 (`at_rest_encryption_enabled = true`)
- CloudWatch 알람 설정 (CPU, 메모리, Evictions)

## 주의사항

- Private Subnet에만 배치 (외부 접근 불가)
- Multi-AZ 구성 시 자동 장애 조치 활성화
- 스냅샷은 새벽 시간대에 자동 생성
- 엔진 버전 업그레이드는 유지보수 창에 자동 적용

## 트러블슈팅

### 연결 안 될 때
```bash
# Security Group 확인
aws ec2 describe-security-groups --group-ids <REDIS_SG_ID>

# VPC 내부에서만 접근 가능 (Lambda/EC2에서 테스트)
redis-cli -h <REDIS_ENDPOINT> -p 6379 ping
```

### 메모리 부족
- 노드 타입 업그레이드 (t3.small → t3.medium)
- `maxmemory-policy` 설정으로 자동 삭제 정책 적용
