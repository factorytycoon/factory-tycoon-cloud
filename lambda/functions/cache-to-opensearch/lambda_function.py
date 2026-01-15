import json
import os
import redis
from datetime import datetime, timezone
from opensearchpy import OpenSearch, RequestsHttpConnection

# Redis 연결
redis_client = redis.Redis(
    host=os.environ['REDIS_ENDPOINT'],
    port=int(os.environ['REDIS_PORT']),
    decode_responses=True,
)

# OpenSearch 연결
host = os.environ['OPENSEARCH_ENDPOINT'].replace('https://', '').replace('http://', '')
master_user = os.environ.get('OPENSEARCH_MASTER_USER', 'user')
master_pass = os.environ.get('OPENSEARCH_MASTER_PASSWORD', '')

opensearch_client = OpenSearch(
    hosts=[{'host': host, 'port': 443}],
    http_auth=(master_user, master_pass),
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection,
)

INDEX_NAME = 'sensor-data'
INDEX_NAME_FLAT = 'sensor-data-flat'

def lambda_handler(event, context):
    try:
        # 1. OpenSearch 인덱스 매핑 설정
        processed_count = 0
        records = []

        # (A) 원본 형태 인덱스 (sensor-data)
        if not opensearch_client.indices.exists(index=INDEX_NAME):
            opensearch_client.indices.create(
                index=INDEX_NAME,
                body={
                    'mappings': {
                        'properties': {
                            'device_id': {'type': 'keyword'},
                            'sensor_id': {'type': 'keyword'},
                            'type': {'type': 'keyword'},
                            'value': {'type': 'float'},
                            'unit': {'type': 'keyword'},
                            'timestamp': {'type': 'date', 'format': 'strict_date_time'},
                            'processed_at': {'type': 'date', 'format': 'strict_date_time'}
                        }
                    }
                },
            )

        # (B) Flat 형태 인덱스 (sensor-data-flat)
        if not opensearch_client.indices.exists(index=INDEX_NAME_FLAT):
            opensearch_client.indices.create(
                index=INDEX_NAME_FLAT,
                body={
                    'mappings': {
                        'properties': {
                            'device_id': {'type': 'keyword'},
                            'sensor_id': {'type': 'keyword'},
                            'timestamp': {'type': 'date', 'format': 'strict_date_time'},
                            'processed_at': {'type': 'date', 'format': 'strict_date_time'}
                        },
                        'dynamic': True  # temp, humi, illu 등 동적 필드 허용
                    }
                },
            )

        # 2. 데이터 수집 (Redis Stream)
        stream_name = 'pending:opensearch_stream'
        group_name = 'opensearch_group'
        consumer_name = 'opensearch_consumer_1'
        try:
            redis_client.xgroup_create(stream_name, group_name, id='0', mkstream=True)
        except redis.exceptions.ResponseError as e:
            if 'BUSYGROUP' not in str(e):
                raise
        batch_size = 1000
        resp = redis_client.xreadgroup(group_name, consumer_name, {stream_name: '>'}, count=batch_size, block=0)
        for stream, messages in resp:
            for msg_id, msg in messages:
                data_json = msg.get('data')
                if data_json:
                    try:
                        records.append(json.loads(data_json))
                    except json.JSONDecodeError:
                        pass
                redis_client.xack(stream_name, group_name, msg_id)

        # 3. 데이터 저장 (Bulk API 사용)
        if records:
            operations = []
            operations_flat = []

            for data in records:
                try:
                    # Timestamp 변환
                    if 'timestamp' in data:
                        ts_val = float(data['timestamp'])
                        timestamp_iso = datetime.fromtimestamp(ts_val, tz=timezone.utc).isoformat()
                    else:
                        timestamp_iso = datetime.now(timezone.utc).isoformat()

                    processed_at = datetime.now(timezone.utc).isoformat()

                    # (A) 원본 형태로 sensor-data에 저장 (배열 그대로)
                    original_data = data.copy()
                    original_data['timestamp'] = timestamp_iso
                    original_data['processed_at'] = processed_at

                    operations.append({"index": {"_index": INDEX_NAME}})
                    operations.append(original_data)

                    # (B) Flat 형태로 sensor-data-flat에 저장
                    # sensors 배열이 있는 경우 처리
                    sensors = data.get('sensors', [])

                    if sensors:
                        # 배열 형태: 각 센서를 하나의 flat 도큐먼트로 변환
                        for sensor in sensors:
                            flat_data = {
                                'device_id': data.get('device_id'),
                                'sensor_id': sensor.get('sensor_id'),
                                'timestamp': timestamp_iso,
                                'processed_at': processed_at
                            }

                            # type을 필드명으로 사용하여 flat하게 저장
                            data_type = sensor.get('type')
                            value = sensor.get('value')
                            unit = sensor.get('unit')
                            state = sensor.get('state')

                            # sensor_type 필드 추가 (명시적으로 타입 저장)
                            if data_type:
                                flat_data['sensor_type'] = data_type

                            if data_type and value is not None:
                                flat_data[data_type] = float(value)
                                if unit:
                                    flat_data[f"{data_type}_unit"] = unit

                            # state 필드가 있으면 추가
                            if state:
                                flat_data['state'] = state

                            operations_flat.append({"index": {"_index": INDEX_NAME_FLAT}})
                            operations_flat.append(flat_data)
                    else:
                        # 개별 센서 형태 (하위 호환성)
                        flat_data = {
                            'device_id': data.get('device_id'),
                            'sensor_id': data.get('sensor_id'),
                            'timestamp': timestamp_iso,
                            'processed_at': processed_at
                        }

                        # type 또는 sensor_type 필드명으로 사용하여 flat하게 저장
                        data_type = data.get('type') or data.get('sensor_type')
                        value = data.get('value')
                        unit = data.get('unit')
                        state = data.get('state')

                        if data_type and value is not None:
                            flat_data[data_type] = float(value)
                            if unit:
                                flat_data[f"{data_type}_unit"] = unit

                        # state 필드가 있으면 추가
                        if state:
                            flat_data['state'] = state

                        operations_flat.append({"index": {"_index": INDEX_NAME_FLAT}})
                        operations_flat.append(flat_data)

                except Exception as e:
                    print(f"Error preparing record: {e}")

            # Bulk 요청 실행 (원본)
            if operations:
                try:
                    response = opensearch_client.bulk(body=operations)
                    if response.get('errors'):
                        print(f"Bulk indexing had errors (original): {response}")
                except Exception as e:
                    print(f"Error in bulk indexing (original): {e}")

            # Bulk 요청 실행 (flat)
            if operations_flat:
                try:
                    response = opensearch_client.bulk(body=operations_flat)
                    processed_count = len(records)
                    if response.get('errors'):
                        print(f"Bulk indexing had errors (flat): {response}")
                except Exception as e:
                    print(f"Error in bulk indexing (flat): {e}")

        print(f"Processed {processed_count} records to OpenSearch")

        return {
            'statusCode': 200,
            'body': json.dumps({'count': processed_count})
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}