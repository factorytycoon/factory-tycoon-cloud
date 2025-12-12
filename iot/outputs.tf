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

output "certificates" {
  value = {
    for key, device in var.devices : key => {
      certificate_pem = tls_self_signed_cert.device[key].cert_pem
      private_key_pem = tls_private_key.device[key].private_key_pem
    }
  }
  sensitive   = true
  description = "디바이스별 인증서 및 개인키 (민감 정보)"
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
