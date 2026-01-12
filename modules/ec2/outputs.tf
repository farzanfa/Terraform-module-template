# =============================================================================
# EC2 Module - Outputs
# =============================================================================

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "private_dns" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.main.private_dns
}

output "availability_zone" {
  description = "Availability zone of the EC2 instance"
  value       = aws_instance.main.availability_zone
}

output "ami_id" {
  description = "AMI ID used by the EC2 instance"
  value       = aws_instance.main.ami
}
