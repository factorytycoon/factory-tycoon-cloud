output "iot_to_cache_function_arn" {
  description = "ARN of IoT to Cache Lambda function"
  value       = aws_lambda_function.iot_to_cache.arn
}

output "cache_to_mongodb_function_arn" {
  description = "ARN of Cache to MongoDB Lambda function"
  value       = aws_lambda_function.cache_to_mongodb.arn
}

output "cache_to_opensearch_function_arn" {
  description = "ARN of Cache to OpenSearch Lambda function"
  value       = aws_lambda_function.cache_to_opensearch.arn
}

output "opensearch_to_mariadb_function_arn" {
  description = "ARN of OpenSearch to MariaDB Lambda function"
  value       = aws_lambda_function.opensearch_to_mariadb.arn
}

output "lambda_role_arn" {
  description = "ARN of Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}
