# IoT Core 모듈

AWS IoT Core의 기본 리소스(Thing, 인증서, Policy)를 배포합니다.

## 아키텍처

```
인터넷 (디바이스)
    ↓
IoT Core MQTT Endpoint (aws-iot-endpoint)  ← VPC 밖, AWS Managed Service
    ↓ (IoT Rule으로 데이터 라우팅)
Lambda / Kinesis / 외부 DB (나중에 추가)
```

**중요**: IoT Core는 VPC 밖에 있으므로, 디바이스는 공개 MQTT 엔드포인트로 직접 접속합니다.

## 포함 리소스

- **IoT Thing**: 디바이스 개별 등록 (thing_name)
- **디바이스 인증서**: TLS 자체 서명 인증서 (certificate PEM)
- **디바이스 개인키**: 인증서와 함께 디바이스에 배포
- **IoT Policy**: MQTT Connect/Publish/Subscribe 권한 제어
  - Publish: telemetry, status 토픽
  - Subscribe/Receive: command 토픽
- **리소스 연결**: 인증서 ↔ Policy, 인증서 ↔ Thing 연결

## 배포 방법

```bash
cd iot

terraform init
terraform plan
terraform apply
```

## 출력값 (apply 후 확인)

```bash
terraform output iot_endpoint          # MQTT 엔드포인트 (예: xxxx.iot.ap-northeast-2.amazonaws.com)
terraform output thing_name             # Thing 이름
terraform output certificate_pem        # 디바이스 인증서 (민감)
terraform output private_key_pem        # 디바이스 개인키 (민감 - 안전하게 보관!)
terraform output mqtt_topics            # MQTT 토픽 목록
```

## 디바이스에 배포

생성된 인증서와 개인키를 **엣지 디바이스**(라즈베리파이, Arduino 등)에 배포:

```bash
# 1. 인증서/키 저장
terraform output -raw certificate_pem > device.crt
terraform output -raw private_key_pem > device.key

# 2. 엣지 디바이스로 SCP/배포
scp device.crt device.key user@edge-device:/path/to/certs/

# 3. 디바이스에서 Python/Node.js로 MQTT 연결
# 엔드포인트: terraform output iot_endpoint
# 인증서 경로: /path/to/certs/device.crt
# 키 경로: /path/to/certs/device.key
```

### Python 예시 (Paho MQTT)

```python
import paho.mqtt.client as mqtt

broker = "YOUR_IOT_ENDPOINT"  # terraform output iot_endpoint
port = 8883
topic_telemetry = "devices/sfc/telemetry"
topic_command = "devices/sfc/command"

client = mqtt.Client(client_id="sfc-edge-device")
client.tls_set(
    ca_certs="/path/to/AmazonRootCA1.pem",
    certfile="/path/to/device.crt",
    keyfile="/path/to/device.key",
    cert_reqs=ssl.CERT_REQUIRED
)
client.connect(broker, port, keepalive=60)

# 발행
client.publish(topic_telemetry, "sensor_data")

# 구독
client.subscribe(topic_command)
client.on_message = on_message_callback
client.loop_forever()
```

## AWS 루트 CA 다운로드

디바이스에서 TLS 검증을 위해 AWS IoT 루트 CA 인증서 필요:

```bash
wget https://www.amazontrust.com/repository/AmazonRootCA1.pem
```

## IoT Rule 추가 (나중에)

추후 Lambda/Kinesis 준비되면, IoT Rule으로 MQTT 데이터를 자동 라우팅:

```hcl
resource "aws_iot_topic_rule" "sensor_data" {
  name                = "sfc_sensor_rule"
  enabled             = true
  sql                 = "SELECT * FROM 'devices/sfc/telemetry'"
  sql_version         = "2016-03-23"

  lambda {
    function_arn = aws_lambda_function.iot_handler.arn  # 나중에 추가
  }
}
```

## 변수 커스터마이징

`terraform.tfvars`에서 수정:
- `thing_name`: 디바이스 이름 변경
- `mqtt_topic_prefix`: 토픽 경로 변경
- `common_tags`: 태그 추가

## 보안 주의사항

- ⚠️ `private_key_pem` 출력은 민감 정보 → `.gitignore`에 자동 추가됨
- ⚠️ 인증서/키는 엣지 디바이스에 안전하게만 배포
- ⚠️ 프로덕션에서는 AWS IoT Device Defender 활성화 고려
