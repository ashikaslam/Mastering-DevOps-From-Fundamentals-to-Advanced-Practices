output "instance_id" {
  description = "The EC2 instance ID"
  value       = aws_instance.app_server.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "public_dns" {
  description = "Public DNS hostname of the EC2 instance"
  value       = aws_instance.app_server.public_dns
}

output "ssh_command" {
  description = "Ready-to-use SSH command"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.app_server.public_ip}"
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${aws_instance.app_server.public_ip}:3001"
}

output "prometheus_url" {
  description = "Prometheus UI URL"
  value       = "http://${aws_instance.app_server.public_ip}:9090"
}

output "django_app_url" {
  description = "Django application URL"
  value       = "http://${aws_instance.app_server.public_ip}:3000"
}
