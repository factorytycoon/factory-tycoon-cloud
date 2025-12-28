import json
import os
import redis
from datetime import datetime, timezone
from opensearchpy import OpenSearch, RequestsHttpConnection

# Redis 연결
redis_client = redis.Redis(
    host=os.environ['REDIS_ENDPOINT'],
    port=int(os.environ['REDIS_PORT']),
    password=os.environ['REDIS_PASSWORD'],
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

def lambda_handler(event, context):
    try:
        # 1. OpenSearch 인덱스 매핑 설정
        # 불필요한 temp, humi, illu 필드 정의를 삭제했습니다.
        processed_count = 0
        records = []
        if not opensearch_client.indices.exists(index=INDEX_NAME):
            opensearch_client.indices.create(
                index=INDEX_NAME,
                body={
                    'mappings': {
                        'properties': {
                            'device_id': {'type': 'keyword'},
                            'sensor_id': {'type': 'keyword'},
                            'type': {'type': 'keyword'},
                            'value': {'type': 'float'},     # 오직 이 값만 사용
                            'unit': {'type': 'keyword'},
                            'timestamp': {'type': 'date'},
                            'processed_at': {'type': 'date'}
                        }
                    }
                },
            )

        # 2. 데이터 수집
        # SQS 제거: Redis Stream만 사용
        else:
            # Redis Stream (XREADGROUP)
            stream_name = 'pending:opensearch_stream'
            group_name = 'opensearch_group'
            consumer_name = 'opensearch_consumer_1'
            try:
                redis_client.xgroup_create(stream_name, group_name, id='0', mkstream=True)
            except redis.exceptions.ResponseError as e:
                if 'BUSYGROUP' not in str(e):
                    raise
            batch_size = 50
            resp = redis_client.xreadgroup(group_name, consumer_name, {stream_name: '>'}, count=batch_size, block=2000)
            for stream, messages in resp:
                for msg_id, msg in messages:
                    data_json = msg.get('data')
                    if data_json:
                        try:
                            records.append(json.loads(data_json))
                        except json.JSONDecodeError:
                            pass
                    redis_client.xack(stream_name, group_name, msg_id)

        # 3. 데이터 저장
        for data in records:
            try:
                # (A) Timestamp 변환
                if 'timestamp' in data:
                    ts_val = float(data['timestamp'])
                    data['timestamp'] = datetime.fromtimestamp(ts_val, tz=timezone.utc).isoformat()
                
                # (B) 값 변환 (실수형)
                if 'value' in data:
                    data['value'] = float(data['value'])
                    
                # [삭제됨] 값을 temp/humi 필드로 복사하던 코드 삭제함

                data['processed_at'] = datetime.now(timezone.utc).isoformat()

                opensearch_client.index(index=INDEX_NAME, body=data)
                processed_count += 1
                
            except Exception as e:
                print(f"Error indexing: {e}")

        print(f"Processed {processed_count} records to OpenSearch")

        return {
            'statusCode': 200,
            'body': json.dumps({'count': processed_count})
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}