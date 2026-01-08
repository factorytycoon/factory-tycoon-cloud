import json
import requests
import os
import logging
from datetime import datetime
import re


# 로깅 설정
logger = logging.getLogger()
logger.setLevel(logging.INFO)

BACKEND_API_URL = os.environ['BACKEND_API_URL'] 

def lambda_handler(event, context):
    """
    SNS에서 트리거된 OpenSearch 데이터를 파싱하여 RDB에 적재하는 메인 함수
    """
    conn = None
    try:
        # 1. SNS 메시지 추출 (SNS는 메시지를 String 형태로 감싸서 보냄)
        logger.info("Event Received: %s", json.dumps(event))
        sns_message = event['Records'][0]['Sns']['Message']
        logger.info("SNS Message Received: %s", sns_message)
        correct_sns_message = re.sub(r',(\s*[\]}])', r'\1', sns_message)
        logger.info("Corrected SNS Message: %s", correct_sns_message)
        # 2. JSON 파싱 (String -> Dict)
        alert_data = json.loads(correct_sns_message)
        logger.info("alert data : %s", alert_data)

        # 3. 공통 데이터 추출
        monitor_name = alert_data.get('monitor_name', 'Unknown')
        trigger_name = alert_data.get('trigger_name', 'Unknown')

        # hits 배열 확인
        hits = alert_data.get('hits', [])

        if not hits:
            logger.info("No hits found in the alert data.")
            return {"statusCode": 200, "body": "No data to insert"}

        # 4. Backend API에 AlarmOsRequest 형식으로 전송
        request_body = alert_data
        
        logger.info("Sending to Backend API: %s", json.dumps(request_body))
        
        response = requests.post(
            BACKEND_API_URL,
            json=request_body,
            timeout=30
        )

        if response.status_code == 200:
            return {
                "statusCode": 200,
                "body": json.dumps("Successfully forwarded to Backend")
            }
        else:
            raise Exception(f"Backend API Error: {response.status_code}")
            
    except Exception as e:
        logger.error("Error: %s", str(e))
        raise e