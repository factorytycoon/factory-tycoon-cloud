output "iot_endpoint" {
  value       = data.aws_iot_endpoint.data.endpoint_address
  description = "IoT Core MQTT 엔드포인트 (모든 디바이스 공통)"
}

output "devices" {
  value = {
    for key, device in var.devices : key => {
      thing_name      = aws_iot_thing.device[key].name
      policy_name     = aws_iot_policy.device[key].name
      certificate_arn = aws_iot_certificate.device[key].arn
      topic_prefix    = device.topic_prefix
      description     = device.description
    }
  }
  description = "디바이스 목록 및 정보"
}



output "mqtt_topics" {
  value = {
    for key, device in var.devices : key => {
      telemetry = "${device.topic_prefix}/telemetry"
      status    = "${device.topic_prefix}/status"
      command   = "${device.topic_prefix}/command"
    }
  }
  description = "디바이스별 MQTT 토픽 목록"
}

output "certificate_paths" {
  value = {
    for key, device in var.devices : key => {
      certificate = data.local_file.device_certificate[key].filename
      private_key = data.local_file.device_private_key[key].filename
      config      = local_file.iot_config[key].filename
      directory   = "${path.module}/certs/${key}"
    }
  }
  description = "생성된 인증서 파일 경로"
}

output "iot_endpoint_value" {
  value       = data.aws_iot_endpoint.data.endpoint_address
  description = "라즈베리파이 연결용 MQTT 엔드포인트"
}