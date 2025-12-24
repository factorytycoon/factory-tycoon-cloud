import json
import os
import redis
from datetime import datetime, timezone
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
    processed_count = 0
    try:
        records = []
        
        # SQS 제거: Redis Stream만 사용

        # 2. Redis Stream (XREADGROUP)
        if not records:
            stream_name = 'pending:mongodb_stream'
            group_name = 'mongodb_group'
            consumer_name = 'mongodb_consumer_1'
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

        # 3. MongoDB에 저장
        if records:
            docs_to_insert = []
            
            for data in records:
                try:
                    # (A) 값(value)을 실수형으로 확실하게 변환
                    if 'value' in data:
                        data['value'] = float(data['value'])

                    # [삭제됨] type에 따라 별도 필드(temp, humi 등)를 만드는 코드 삭제함
                    # 이제 무조건 'value' 필드 하나에 값만 들어갑니다.

                    # (B) 날짜 변환 (Epoch -> ISODate)
                    if 'timestamp' in data:
                        data['timestamp_dt'] = datetime.fromtimestamp(float(data['timestamp']), tz=timezone.utc)
                    
                    # (C) 데이터 처리 시간 기록
                    data['processed_at'] = datetime.now(timezone.utc)
                    
                    docs_to_insert.append(data)
                    
                except Exception as parse_error:
                    print(f"Error parsing record: {parse_error}")

            if docs_to_insert:
                result = collection.insert_many(docs_to_insert)
                processed_count = len(result.inserted_ids)

        print(f"Successfully processed {processed_count} records to MongoDB")

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Done', 'count': processed_count})
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}