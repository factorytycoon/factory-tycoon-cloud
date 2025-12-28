import json
import os
import redis
 
import time

# Redis 연결
redis_client = redis.Redis(
    host=os.environ['REDIS_ENDPOINT'],
    port=int(os.environ['REDIS_PORT']),
    password=os.environ['REDIS_PASSWORD'],
    decode_responses=True
)
redis_client_local = redis.Redis(
    host=os.environ['REDIS_ENDPOINT_LOCAL'],
    port=int(os.environ['REDIS_PORT_LOCAL']),
    password=os.environ['REDIS_PASSWORD_LOCAL'],
    decode_responses=True
)

 

def lambda_handler(event, context):
    """
    IoT Core에서 받은 표준화된 데이터(device_id, type, value 등)를 처리
    Schema:
      - device_id: 설비 ID (예: ft-pi-001)
      - sensor_id: 센서 고유 ID (예: 001)
      - type: 데이터 타입 (예: temp, humi, illu)
      - value: 측정값 (float)
      - unit: 단위
      - timestamp: Epoch Time
    """
    try:
        # 1. 데이터 수신 및 로그 확인
        print(f"Received event: {json.dumps(event)}")
        data = event
        
        # 2. 필드 추출 (새로운 스키마 적용)
        device_id = data.get('device_id', 'unknown')   # 예: ft-pi-001
        sensor_id = data.get('sensor_id', 'unknown')   # 예: 001
        data_type = data.get('type', 'unknown')        # 예: temp, humi, illu
        unit = data.get('unit', '')
        
        # value 처리 (None 방지)
        raw_value = data.get('value')
        value = float(raw_value) if raw_value is not None else 0.0

        # Timestamp 처리
        raw_timestamp = data.get('timestamp')
        if raw_timestamp is not None:
            timestamp = float(raw_timestamp)
        else:
            timestamp = time.time()
            data['timestamp'] = int(timestamp)

        print(f"Processing - Device: {device_id}, Type: {data_type}, Value: {value}")

        # 3. Redis에 저장
        
        # (A) 최신 상태 저장 (Hash) -> '현재 상태' 대시보드용
        # 키 예시: device:ft-pi-001:latest
        # 중요: 들어오는 키가 'value' 하나이므로, Redis에 저장할 때는 'temp', 'humi' 처럼 type 이름을 필드명으로 써야 덮어쓰지 않습니다.
        redis_key_latest = f"device:{device_id}:latest"
        
        # Hash에 업데이트할 필드들 구성
        # 예: temp 데이터가 오면 -> {'temp': 23.5, 'temp_unit': 'degree', 'last_update': 1766...} 저장
        mapping_data = {
            data_type: value,                 # 예: "temp": 23.55
            f"{data_type}_unit": unit,        # 예: "temp_unit": "degree"
            "sensor_id": sensor_id,           # 마지막으로 업데이트한 센서 ID
            "last_updated": int(timestamp)    # 마지막 업데이트 시간
        }
        
        redis_client.hset(redis_key_latest, mapping=mapping_data)
        redis_client_local.hset(redis_key_latest, mapping=mapping_data)
        
        # (B) 시계열 데이터 저장 (Sorted Set) -> '그래프' 조회용
        # 키 예시: device:ft-pi-001:timeseries
        # 데이터 전체(JSON)를 저장하여 나중에 필터링 가능하게 함
        redis_key_series = f"device:{device_id}:timeseries"
        redis_client.zadd(redis_key_series, {json.dumps(data): timestamp})
        redis_client_local.zadd(redis_key_series, {json.dumps(data): timestamp})
        
        # 4. 처리 대기 큐에 추가 (MongoDB, OpenSearch 저장용)
        message_body = json.dumps(data)
        
        # Redis Stream (권장)
        redis_client.xadd(
            'pending:mongodb_stream',
            {'data': message_body},
            maxlen=10000,
            approximate=True
        )
        redis_client.xadd(
            'pending:opensearch_stream',
            {'data': message_body},
            maxlen=10000,
            approximate=True
        )
        redis_client_local.xadd(
            'pending:mongodb_stream',
            {'data': message_body},
            maxlen=10000,
            approximate=True
        )
        redis_client_local.xadd(
            'pending:opensearch_stream',
            {'data': message_body},
            maxlen=10000,
            approximate=True
        )
        # SQS 제거: Redis Stream만 사용
        
        print(f"Successfully stored data for {device_id} ({data_type})")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Data processed successfully',
                'device_id': device_id,
                'type': data_type,
                'value': value
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }