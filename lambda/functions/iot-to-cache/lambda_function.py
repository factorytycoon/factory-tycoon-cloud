import json
import os
import redis

# Redis 연결
redis_client = redis.Redis(
    host=os.environ['REDIS_ENDPOINT'],
    port=int(os.environ['REDIS_PORT']),
    decode_responses=True
)

def lambda_handler(event, context):
    """
    IoT Core에서 받은 데이터를 ElastiCache에 저장
    """
    try:
        print(f"Received event: {json.dumps(event)}")
        
        # IoT 메시지 파싱
        # event 자체가 IoT 메시지 데이터
        data = event
        
        # 센서 ID 추출 (데이터 구조에 따라 수정 필요)
        sensor_id = data.get('sensor_id', 'unknown')
        timestamp = data.get('timestamp', '')
        
        # Redis에 저장
        # 1. 최신 데이터를 Hash로 저장
        redis_key = f"sensor:{sensor_id}:latest"
        redis_client.hset(redis_key, mapping=data)
        
        # 2. 시계열 데이터를 Sorted Set에 저장
        timeseries_key = f"sensor:{sensor_id}:timeseries"
        redis_client.zadd(timeseries_key, {json.dumps(data): float(timestamp)})
        
        # 3. 처리 대기 큐에 추가 (Lambda 2, 3에서 처리)
        redis_client.lpush('pending:mongodb', json.dumps(data))
        redis_client.lpush('pending:opensearch', json.dumps(data))
        
        print(f"Successfully stored data for sensor {sensor_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Data stored successfully',
                'sensor_id': sensor_id
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
