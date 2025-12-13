import json
import os
import redis
from pymongo import MongoClient
from datetime import datetime

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
    ElastiCache에서 데이터를 읽어 MongoDB에 저장
    """
    try:
        processed_count = 0
        batch_size = 100  # 한 번에 처리할 데이터 개수
        
        # Redis 큐에서 데이터 가져오기
        for _ in range(batch_size):
            data_json = redis_client.rpop('pending:mongodb')
            if not data_json:
                break
            
            data = json.loads(data_json)
            
            # MongoDB에 저장
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
