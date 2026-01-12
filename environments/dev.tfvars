# =============================================================================
# Development Environment Configuration
# =============================================================================
# This file contains ALL variables for the dev environment.
# No defaults exist in variables.tf - everything is controlled here.
# =============================================================================

# =============================================================================
# NAMING AND TAGS
# =============================================================================

project_name = "password-manager"
environment  = "dev"
aws_region   = "ap-south-1"
owner        = "DevOps Team"
cost_center  = "Engineering"

# Additional custom tags
custom_tags = {
  Application = "Password Manager"
  Team        = "Platform Engineering"
  ManagedBy   = "Terraform"
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24"]
private_subnet_cidrs = ["10.0.10.0/24"]
availability_zones   = ["ap-south-1a"]

# NAT Gateway
enable_nat_gateway = true
single_nat_gateway = true # Single NAT for cost optimization in dev

# =============================================================================
# EC2 CONFIGURATION - Application Server
# =============================================================================

instance_type              = "t3.medium"
root_volume_size           = 60
enable_detailed_monitoring = false

# =============================================================================
# EC2 CONFIGURATION - Bastion Host
# =============================================================================

bastion_instance_type     = "t3.micro"
bastion_assign_elastic_ip = false

# =============================================================================
# SSH ACCESS
# =============================================================================

# SSH key pair name (must exist in AWS)
# SSH key pair name (must exist in AWS)
key_pair_name = "password-manager-dev-key"

# Allowed SSH CIDRs for bastion access
# Replace with your actual IP address
allowed_ssh_cidrs = ["0.0.0.0/0"] # WARNING: Open to world for dev, lock down to specific IP in production

# =============================================================================
# APPLICATION CONFIGURATION
# =============================================================================

application_ports = [8000]
health_check_path = "/health"

# Database Configuration
db_password = "secure_dev_password_123!" # CHANGE THIS!
db_user     = "password_manager"
db_name     = "password_manager"

# =============================================================================
# DOMAIN AND CERTIFICATE CONFIGURATION
# =============================================================================

# Domain settings
domain_name        = "terrifiminds.com" # Updated to likely domain based on paths
frontend_subdomain = "app-dev"
api_subdomain      = "api-dev"

# ACM Certificate
create_acm_certificate       = true
existing_acm_certificate_arn = "" # Only needed if create_acm_certificate = false

# =============================================================================
# MONITORING CONFIGURATION
# =============================================================================

log_retention_days = 30 # Shorter retention for dev

# =============================================================================
# ECR CONFIGURATION
# =============================================================================

ecr_image_tag_mutability       = "MUTABLE"
ecr_scan_on_push               = true
ecr_image_count_to_keep        = 10
ecr_untagged_image_expiry_days = 7
