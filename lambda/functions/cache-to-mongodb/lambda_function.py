import json
import os
import redis
from datetime import datetime
from pymongo import MongoClient

# Redis 연결
redis_client = redis.Redis(
    host=os.environ['REDIS_ENDPOINT'],
    port=int(os.environ['REDIS_PORT']),
    decode_responses=True
)

# MongoDB 연결
mongo_client = MongoClient(os.environ['MONGODB_URI'])
db = mongo_client[os.environ['MONGODB_DB']]
collection = db['sensor_data']

def lambda_handler(event, context):
    """
    SQS 메시지 또는 직접 호출 이벤트를 받아 MongoDB에 저장.
    우선 SQS 트리거로 전달된 경우 `event['Records']`를 처리하고,
    그렇지 않으면 Redis 큐에서 소량을 읽어 처리합니다.
    """
    processed_count = 0
    try:
        records = []
        # SQS 이벤트 처리
        if isinstance(event, dict) and event.get('Records'):
            for rec in event['Records']:
                body = rec.get('body')
                if body:
                    records.append(json.loads(body))
        else:
            # 폴백: Redis 큐에서 몇 개 가져와 처리
            for _ in range(50):
                data_json = redis_client.rpop('pending:mongodb')
                if not data_json:
                    break
                records.append(json.loads(data_json))

        # MongoDB에 저장
        for data in records:
            data['processed_at'] = datetime.utcnow()
            collection.insert_one(data)
            processed_count += 1

        print(f"Processed {processed_count} records to MongoDB")

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
