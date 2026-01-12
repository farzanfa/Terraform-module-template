# =============================================================================
# Bastion Module - Outputs
# =============================================================================

output "instance_id" {
  description = "ID of the bastion EC2 instance"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "Public IP address of the bastion"
  value       = var.assign_elastic_ip ? aws_eip.bastion[0].public_ip : aws_instance.bastion.public_ip
}

output "private_ip" {
  description = "Private IP address of the bastion"
  value       = aws_instance.bastion.private_ip
}

output "security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "ssh_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh -i <your-key.pem> ec2-user@${var.assign_elastic_ip ? aws_eip.bastion[0].public_ip : aws_instance.bastion.public_ip}"
}
