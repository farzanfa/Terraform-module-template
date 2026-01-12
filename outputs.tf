# =============================================================================
# Network Outputs
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# =============================================================================
# Load Balancer Outputs
# =============================================================================

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

# =============================================================================
# CloudFront Outputs
# =============================================================================

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.s3_cloudfront.cloudfront_distribution_id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.s3_cloudfront.cloudfront_domain_name
}

output "cloudfront_distribution_url" {
  description = "HTTPS URL of the CloudFront distribution"
  value       = "https://${module.s3_cloudfront.cloudfront_domain_name}"
}

output "frontend_s3_bucket_name" {
  description = "Name of the S3 bucket for frontend assets"
  value       = module.s3_cloudfront.s3_bucket_name
}

output "frontend_s3_bucket_arn" {
  description = "ARN of the S3 bucket for frontend assets"
  value       = module.s3_cloudfront.s3_bucket_arn
}

# =============================================================================
# EC2 Outputs
# =============================================================================

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = module.ec2.private_ip
}

# =============================================================================
# Bastion Outputs
# =============================================================================

output "bastion_instance_id" {
  description = "ID of the bastion EC2 instance"
  value       = module.bastion.instance_id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = module.bastion.ssh_command
}

output "private_ec2_ssh_via_bastion" {
  description = "SSH command to connect to private EC2 via bastion (ProxyJump)"
  value       = "ssh -J ec2-user@${module.bastion.public_ip} ec2-user@${module.ec2.private_ip}"
}

# =============================================================================
# Monitoring Outputs
# =============================================================================

output "backend_log_group_name" {
  description = "Name of the CloudWatch log group for backend application"
  value       = module.monitoring.backend_log_group_name
}

output "system_log_group_name" {
  description = "Name of the CloudWatch log group for system logs"
  value       = module.monitoring.system_log_group_name
}

# =============================================================================
# DNS Configuration Outputs (for manual DNS setup)
# =============================================================================

output "dns_records_to_create" {
  description = "DNS records that need to be created for the application"
  value = {
    frontend = {
      type  = "CNAME"
      name  = "${var.frontend_subdomain}.${var.domain_name}"
      value = module.s3_cloudfront.cloudfront_domain_name
    }
    api = {
      type  = "CNAME"
      name  = "${var.api_subdomain}.${var.domain_name}"
      value = module.alb.alb_dns_name
    }
  }
}
