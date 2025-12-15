import json
import os
from datetime import datetime

import redis
from opensearchpy import OpenSearch, RequestsHttpConnection

# Redis 연결
redis_client = redis.Redis(
    host=os.environ['REDIS_ENDPOINT'],
    port=int(os.environ['REDIS_PORT']),
    decode_responses=True,
)

# OpenSearch 연결: 마스터 사용자 기본 인증
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
    """SQS 메시지에서 데이터를 읽어 OpenSearch에 저장"""
    try:
        # OpenSearch 인덱스 생성 (없는 경우)
        if not opensearch_client.indices.exists(index=INDEX_NAME):
            opensearch_client.indices.create(
                index=INDEX_NAME,
                body={
                    'mappings': {
                        'properties': {
                            'sensor_id': {'type': 'keyword'},
                            'timestamp': {'type': 'date'},
                            # 'value': {'type': 'float'},
                            # 'processed_at': {'type': 'date'},
                        }
                    }
                },
            )

        processed_count = 0

        # SQS Records 처리 (있으면 SQS에서, 없으면 Redis에서 폴링)
        if 'Records' in event:
            # SQS 이벤트
            for record in event['Records']:
                try:
                    data_json = record['body']
                    data = json.loads(data_json)

                    # OpenSearch에 저장
                    data['processed_at'] = datetime.utcnow().isoformat()
                    opensearch_client.index(
                        index=INDEX_NAME,
                        body=data,
                    )
                    processed_count += 1
                except Exception as e:
                    print(f"Error processing SQS record: {str(e)}")
        else:
            # 폴백: Redis에서 직접 읽기 (SQS 없을 시)
            batch_size = 100
            for _ in range(batch_size):
                data_json = redis_client.rpop('pending:opensearch')
                if not data_json:
                    break

                data = json.loads(data_json)
                data['processed_at'] = datetime.utcnow().isoformat()
                opensearch_client.index(
                    index=INDEX_NAME,
                    body=data,
                )
                processed_count += 1

        print(f"Processed {processed_count} records to OpenSearch")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Processed {processed_count} records',
                'processed_count': processed_count,
            }),
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
            }),
        }
