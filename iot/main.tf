# ==========================================
# IoT Core: 기본 설정 (VPC 밖, AWS Managed)
# ==========================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# 1. IoT Thing 생성 (디바이스 등록)
resource "aws_iot_thing" "device" {
  for_each = var.devices
  name     = each.value.thing_name

  lifecycle {
    create_before_destroy = false
  }
}


# 2. 수동 생성된 인증서/키 파일 참조
data "local_file" "device_certificate" {
  for_each = var.devices
  filename = "${path.module}/certs/${each.key}/certificate.pem"
}

data "local_file" "device_private_key" {
  for_each = var.devices
  filename = "${path.module}/certs/${each.key}/private-key.pem"
}

# 3. AWS IoT에 인증서 등록 (수동 인증서 사용)
resource "aws_iot_certificate" "device" {
  for_each        = var.devices
  certificate_pem = data.local_file.device_certificate[each.key].content
  ca_pem          = ""
  active          = true

  lifecycle {
    create_before_destroy = false
  }
}

# 4. IoT Policy 정의 (MQTT 권한) - 디바이스별
# resource "aws_iot_policy" "device" {
#   for_each = var.devices
#   name     = "${var.project_name}-policy-${each.key}"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "iot:Connect"
#         ]
#         Resource = [
#           "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:client/${each.value.thing_name}"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "iot:Publish"
#         ]
#         Resource = [
#           "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/${each.value.topic_prefix}/telemetry",
#           "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/${each.value.topic_prefix}/status"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "iot:Subscribe"
#         ]
#         Resource = [
#           "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/${each.value.topic_prefix}/command"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "iot:Receive"
#         ]
#         Resource = [
#           "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/${each.value.topic_prefix}/command"
#         ]
#       }
#     ]
#   })
# }
resource "aws_iot_policy" "device" {
  for_each = var.devices
  name     = "${var.project_name}-policy-${each.key}"

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iot:Connect",
        "iot:Publish",
        "iot:Subscribe",
        "iot:Receive"
      ],
      "Resource": "*"
    }
  ]
  })
}

# 5. 인증서와 정책 연결
resource "aws_iot_policy_attachment" "device" {
  for_each = var.devices
  policy   = aws_iot_policy.device[each.key].name
  target   = aws_iot_certificate.device[each.key].arn
}

# 6. 인증서와 Thing 연결
resource "aws_iot_thing_principal_attachment" "device" {
  for_each  = var.devices
  thing     = aws_iot_thing.device[each.key].name
  principal = aws_iot_certificate.device[each.key].arn
}

# 7. IoT Data Endpoint 조회 (디바이스 접속용)
data "aws_iot_endpoint" "data" {
  endpoint_type = "iot:Data-ATS"
}

# 8. AWS Root CA 인증서 다운로드
data "http" "aws_root_ca" {
  url = "https://www.amazontrust.com/repository/AmazonRootCA1.pem"
}


# 9. 라즈베리파이용 CA 파일 자동 생성 (AWS Root CA)

resource "local_file" "aws_root_ca" {
  for_each        = var.devices
  content         = data.http.aws_root_ca.response_body
  filename        = "${path.module}/certs/${each.key}/ca.pem"
  file_permission = "0644"

  lifecycle {
    ignore_changes = [content]
  }
}

# 10. 라즈베리파이 연결 설정 파일 자동 생성 (config.json)
resource "local_file" "iot_config" {
  for_each    = var.devices
  content = jsonencode({
    endpoint   = data.aws_iot_endpoint.data.endpoint_address
    client_id  = each.value.thing_name
    cert_path  = "${path.module}/certs/${each.key}/certificate.pem"
    key_path   = "${path.module}/certs/${each.key}/private-key.pem"
    ca_path    = "${path.module}/certs/${each.key}/ca.pem"
    topics = {
      telemetry = "${each.value.topic_prefix}/telemetry"
      status    = "${each.value.topic_prefix}/status"
      command   = "${each.value.topic_prefix}/command"
    }
  })
  filename        = "${path.module}/certs/${each.key}/config.json"
  file_permission = "0644"

  lifecycle {
    ignore_changes = [content]
  }
}
