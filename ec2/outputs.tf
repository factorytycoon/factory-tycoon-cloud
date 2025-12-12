output "instance_id" {
  value       = aws_instance.main.id
  description = "EC2 인스턴스 ID"
}

output "instance_public_ip" {
  value       = aws_instance.main.public_ip
  description = "EC2 인스턴스 Public IP"
}

output "instance_private_ip" {
  value       = aws_instance.main.private_ip
  description = "EC2 인스턴스 Private IP"
}

output "security_group_id" {
  value       = aws_security_group.ec2.id
  description = "EC2 Security Group ID"
}

output "ssh_connection" {
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.main.public_ip}"
  description = "SSH 접속 명령어"
}

output "application_urls" {
  value = {
    port_8080 = "http://${aws_instance.main.public_ip}:8080"
    port_8081 = "http://${aws_instance.main.public_ip}:8081"
  }
  description = "애플리케이션 접속 URL"
}
