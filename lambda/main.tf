# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project}-lambda-role"
  }
}

# Lambda Basic Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda VPC Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda Custom Policy for ElastiCache and OpenSearch
resource "aws_iam_role_policy" "lambda_custom_policy" {
  name = "${var.project}-lambda-custom-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticache:DescribeCacheClusters",
          "es:ESHttpGet",
          "es:ESHttpPut",
          "es:ESHttpPost",
          "es:ESHttpHead",
          "es:ESHttpDelete"
        ]
        Resource = "*"
      }
    ]
  })
}

# SQS consume permissions for Lambda execution role
resource "aws_iam_role_policy" "lambda_sqs_consume" {
  name = "${var.project}-lambda-sqs-consume"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ],
        Resource = [
          aws_sqs_queue.mongodb_queue.arn,
          aws_sqs_queue.opensearch_queue.arn
        ]
      }
    ]
  })
}

# SQS send permissions for iot-to-cache Lambda
resource "aws_iam_role_policy" "lambda_sqs_send" {
  name = "${var.project}-lambda-sqs-send"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage"
        ],
        Resource = [
          aws_sqs_queue.mongodb_queue.arn,
          aws_sqs_queue.opensearch_queue.arn
        ]
      }
    ]
  })
}

# Lambda 1: IoT Core -> ElastiCache
data "archive_file" "iot_to_cache" {
  type        = "zip"
  source_dir  = "${path.module}/functions/iot-to-cache"
  output_path = "${path.module}/builds/iot-to-cache.zip"
}

resource "aws_lambda_function" "iot_to_cache" {
  filename         = data.archive_file.iot_to_cache.output_path
  function_name    = "${var.project}-iot-to-cache"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.iot_to_cache.output_base64sha256
  runtime         = "python3.11"
  timeout         = 60
  memory_size     = 256

  vpc_config {
    subnet_ids         = data.terraform_remote_state.vpc.outputs.private_subnets
    security_group_ids = [
      data.terraform_remote_state.security_groups.outputs.common_sg_id,
      data.terraform_remote_state.security_groups.outputs.data_sg_id
    ]
  }

  environment {
    variables = {
      REDIS_ENDPOINT = data.terraform_remote_state.elasticache.outputs.redis_primary_endpoint
      REDIS_PORT     = data.terraform_remote_state.elasticache.outputs.redis_port
      MONGODB_QUEUE_URL = aws_sqs_queue.mongodb_queue.id
      OPENSEARCH_QUEUE_URL = aws_sqs_queue.opensearch_queue.id
    }
  }

  tags = {
    Name = "${var.project}-iot-to-cache"
  }
}

# Lambda 2: ElastiCache -> MongoDB
data "archive_file" "cache_to_mongodb" {
  type        = "zip"
  source_dir  = "${path.module}/functions/cache-to-mongodb"
  output_path = "${path.module}/builds/cache-to-mongodb.zip"
}

resource "aws_lambda_function" "cache_to_mongodb" {
  filename         = data.archive_file.cache_to_mongodb.output_path
  function_name    = "${var.project}-cache-to-mongodb"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.cache_to_mongodb.output_base64sha256
  runtime         = "python3.11"
  timeout         = 300
  memory_size     = 512

  vpc_config {
    subnet_ids         = data.terraform_remote_state.vpc.outputs.private_subnets
    security_group_ids = [
      data.terraform_remote_state.security_groups.outputs.common_sg_id,
      data.terraform_remote_state.security_groups.outputs.data_sg_id
    ]
  }

  environment {
    variables = {
      REDIS_ENDPOINT = data.terraform_remote_state.elasticache.outputs.redis_primary_endpoint
      REDIS_PORT     = data.terraform_remote_state.elasticache.outputs.redis_port
      MONGODB_URI    = var.mongodb_uri
      MONGODB_DB     = var.mongodb_database
    }
  }

  tags = {
    Name = "${var.project}-cache-to-mongodb"
  }
}

# Lambda 3: ElastiCache -> OpenSearch
data "archive_file" "cache_to_opensearch" {
  type        = "zip"
  source_dir  = "${path.module}/functions/cache-to-opensearch"
  output_path = "${path.module}/builds/cache-to-opensearch.zip"
}

resource "aws_lambda_function" "cache_to_opensearch" {
  filename         = data.archive_file.cache_to_opensearch.output_path
  function_name    = "${var.project}-cache-to-opensearch"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.cache_to_opensearch.output_base64sha256
  runtime         = "python3.11"
  timeout         = 300
  memory_size     = 512

  vpc_config {
    subnet_ids         = data.terraform_remote_state.vpc.outputs.private_subnets
    security_group_ids = [
      data.terraform_remote_state.security_groups.outputs.common_sg_id,
      data.terraform_remote_state.security_groups.outputs.data_sg_id
    ]
  }

  environment {
    variables = {
      REDIS_ENDPOINT           = data.terraform_remote_state.elasticache.outputs.redis_primary_endpoint
      REDIS_PORT               = data.terraform_remote_state.elasticache.outputs.redis_port
      OPENSEARCH_ENDPOINT      = data.terraform_remote_state.opensearch.outputs.endpoint
      OPENSEARCH_MASTER_USER   = data.terraform_remote_state.opensearch.outputs.master_user_name
      OPENSEARCH_MASTER_PASSWORD = data.terraform_remote_state.opensearch.outputs.master_user_password
    }
  }

  tags = {
    Name = "${var.project}-cache-to-opensearch"
  }
}

# IoT Rule for Lambda 1
resource "aws_iot_topic_rule" "iot_to_lambda" {
  name        = "${replace(var.project, "-", "_")}_iot_to_lambda"
  description = "Forward IoT data to Lambda"
  enabled     = true
  sql         = "SELECT * FROM '${var.iot_topic}'"
  sql_version = "2016-03-23"

  lambda {
    function_arn = aws_lambda_function.iot_to_cache.arn
  }
}

# Lambda Permission for IoT
resource "aws_lambda_permission" "iot_invoke" {
  statement_id  = "AllowExecutionFromIoT"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.iot_to_cache.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.iot_to_lambda.arn
}

# EventBridge Rule for Lambda 2 (매 5분마다 실행)
#### SQS for immediate triggering ####
resource "aws_sqs_queue" "mongodb_queue" {
  name                       = "${var.project}-mongodb-queue"
  visibility_timeout_seconds = 330
  message_retention_seconds  = 1209600
}

resource "aws_sqs_queue" "opensearch_queue" {
  name                       = "${var.project}-opensearch-queue"
  visibility_timeout_seconds = 330
  message_retention_seconds  = 1209600
}

# SQS -> Lambda trigger for MongoDB
resource "aws_lambda_event_source_mapping" "mongodb_sqs_trigger" {
  event_source_arn  = aws_sqs_queue.mongodb_queue.arn
  function_name     = aws_lambda_function.cache_to_mongodb.arn
  batch_size        = 10
  maximum_batching_window_in_seconds = 0
  enabled           = true
}

# Permissions: allow SQS to invoke Lambda
resource "aws_lambda_permission" "allow_sqs_mongodb" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cache_to_mongodb.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.mongodb_queue.arn
}

# SQS -> Lambda trigger for OpenSearch (real-time, not scheduled)
resource "aws_lambda_event_source_mapping" "opensearch_sqs_trigger" {
  event_source_arn  = aws_sqs_queue.opensearch_queue.arn
  function_name     = aws_lambda_function.cache_to_opensearch.arn
  batch_size        = 10
  maximum_batching_window_in_seconds = 0
  enabled           = true
}

# Permissions: allow SQS to invoke Lambda for OpenSearch
resource "aws_lambda_permission" "allow_sqs_opensearch" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cache_to_opensearch.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.opensearch_queue.arn
}
