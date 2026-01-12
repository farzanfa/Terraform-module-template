# =============================================================================
# Development Environment Configuration
# =============================================================================

# -----------------------------------------------------------------------------
# General Settings
# -----------------------------------------------------------------------------

environment  = "dev"
project_name = "password-manager"
aws_region   = "ap-south-1"
owner        = "DevOps Team"
cost_center  = "Engineering"

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
availability_zones   = ["ap-south-1a", "ap-south-1b"]

# NAT Gateway (single for cost optimization in dev)
enable_nat_gateway = true
single_nat_gateway = true

# -----------------------------------------------------------------------------
# EC2 Configuration
# -----------------------------------------------------------------------------

# Instance type (smaller for dev)
instance_type = "t3.medium"

# SSH key pair (replace with your key pair name)
key_pair_name = "password-manager-dev-key"

# Allowed SSH CIDRs (replace with your IP addresses)
# Example: ["203.0.113.0/32", "198.51.100.0/24"]
allowed_ssh_cidrs = []

# Volume sizes
root_volume_size = 30
data_volume_size = 50

# Monitoring (basic for dev)
enable_detailed_monitoring = false

# -----------------------------------------------------------------------------
# Application Configuration
# -----------------------------------------------------------------------------

backend_port      = 8000
health_check_path = "/health"

# -----------------------------------------------------------------------------
# Domain Configuration
# -----------------------------------------------------------------------------

# Replace with your actual domain
domain_name        = "example.com"
frontend_subdomain = "app-dev"
api_subdomain      = "api-dev"

# Set to false if using existing certificate
create_acm_certificate = true

# If using existing certificate, provide ARN:
# existing_acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxx"

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

# Shorter retention for dev (30 days)
log_retention_days = 30
