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
