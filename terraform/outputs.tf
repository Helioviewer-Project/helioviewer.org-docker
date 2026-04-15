output "instance_public_ip" {
  description = "Public IP address of the Helioviewer EC2 instance"
  value       = aws_eip.helioviewer.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the Helioviewer EC2 instance"
  value       = aws_instance.helioviewer.public_dns
}

output "private_key_file" {
  description = "Path to the generated SSH private key file"
  value       = local_sensitive_file.private_key.filename
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -L localhost:9323:localhost:9323 -i ${local_sensitive_file.private_key.filename} ubuntu@${aws_eip.helioviewer.public_ip}"
}

output "bootstrap_log" {
  description = "Command to follow the bootstrap log (useful to watch first-boot progress)"
  value       = "ssh -i ${local_sensitive_file.private_key.filename} ubuntu@${aws_eip.helioviewer.public_ip} 'tail -f /var/log/helioviewer-bootstrap.log'"
}

output "web_client_url" {
  description = "URL for the Helioviewer web client"
  value       = "http://${aws_eip.helioviewer.public_ip}:${var.client_port}"
}

output "api_url" {
  description = "URL for the Helioviewer API"
  value       = "http://${aws_eip.helioviewer.public_ip}:${var.api_port}"
}

output "superset_url" {
  description = "URL for Apache Superset"
  value       = "http://${aws_eip.helioviewer.public_ip}:8088"
}
