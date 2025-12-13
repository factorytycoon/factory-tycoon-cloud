output "redis_primary_endpoint" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "Redis Primary 엔드포인트 (쓰기/읽기)"
}

output "redis_reader_endpoint" {
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
  description = "Redis Reader 엔드포인트 (읽기 전용, Multi-AZ일 때)"
}

output "redis_port" {
  value       = var.redis_port
  description = "Redis 포트"
}

output "redis_connection_string" {
  value       = "${aws_elasticache_replication_group.redis.primary_endpoint_address}:${var.redis_port}"
  description = "Redis 연결 문자열"
}
