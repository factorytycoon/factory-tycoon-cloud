output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = [aws_subnet.public_a.id, aws_subnet.public_c.id]
}

output "private_subnets" {
  value = [aws_subnet.private_a.id, aws_subnet.private_c.id]
}
