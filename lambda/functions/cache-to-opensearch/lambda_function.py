import json
import os
import redis
from opensearchpy import OpenSearch, RequestsHttpConnection
from datetime import datetime

# Redis 연결
redis_client = redis.Redis(
    host=os.environ['REDIS_ENDPOINT'],
    port=int(os.environ['REDIS_PORT']),
    decode_responses=True
)

# OpenSearch 연결
opensearch_client = OpenSearch(
    hosts=[{'host': os.environ['OPENSEARCH_ENDPOINT'].replace('https://', '').replace('http://', ''), 'port': 443}],
    http_auth=('admin', 'Admin123!'),  # 실제 자격증명으로 교체 필요
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection
)

INDEX_NAME = 'sensor-data'

def lambda_handler(event, context):
    """
    ElastiCache에서 데이터를 읽어 OpenSearch에 저장
    """
    try:
        processed_count = 0
        batch_size = 100  # 한 번에 처리할 데이터 개수
        
        # OpenSearch 인덱스 생성 (없는 경우)
        if not opensearch_client.indices.exists(index=INDEX_NAME):
            opensearch_client.indices.create(
                index=INDEX_NAME,
                body={
                    'mappings': {
                        'properties': {
                            'sensor_id': {'type': 'keyword'},
                            'timestamp': {'type': 'date'},
                            'value': {'type': 'float'},
                            'processed_at': {'type': 'date'}
                        }
                    }
                }
            )
        
        # Redis 큐에서 데이터 가져오기
        for _ in range(batch_size):
            data_json = redis_client.rpop('pending:opensearch')
            if not data_json:
                break
            
            data = json.loads(data_json)
            
            # OpenSearch에 저장
            data['processed_at'] = datetime.utcnow().isoformat()
            opensearch_client.index(
                index=INDEX_NAME,
                body=data
            )
            
            processed_count += 1
        
        print(f"Processed {processed_count} records to OpenSearch")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Processed {processed_count} records',
                'processed_count': processed_count
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
