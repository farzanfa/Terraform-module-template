# =============================================================================
# Variables - All values must be specified in tfvars files
# =============================================================================

# =============================================================================
# Common Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "owner" {
  description = "Owner of the infrastructure for tagging"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing purposes"
  type        = string
}

variable "custom_tags" {
  description = "Additional custom tags to apply to all resources"
  type        = map(string)
}

# =============================================================================
# Network Variables
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for subnet deployment"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway for private subnet internet access"
  type        = bool
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs (cost optimization for non-prod)"
  type        = bool
}

# =============================================================================
# EC2 Variables
# =============================================================================

variable "instance_type" {
  description = "EC2 instance type for application server"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed for SSH access to bastion"
  type        = list(string)
  sensitive   = true
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for EC2"
  type        = bool
}

# =============================================================================
# Bastion Variables
# =============================================================================

variable "bastion_instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
}

variable "bastion_assign_elastic_ip" {
  description = "Whether to assign an Elastic IP to the bastion host"
  type        = bool
}

# =============================================================================
# Application Variables
# =============================================================================

variable "backend_port" {
  description = "Port the backend application listens on"
  type        = number
}

variable "health_check_path" {
  description = "Health check path for the load balancer"
  type        = string
}

# =============================================================================
# Domain and Certificate Variables
# =============================================================================

variable "domain_name" {
  description = "Primary domain name for the application"
  type        = string
}

variable "frontend_subdomain" {
  description = "Subdomain for the frontend (e.g., 'app' for app.example.com)"
  type        = string
}

variable "api_subdomain" {
  description = "Subdomain for the API (e.g., 'api' for api.example.com)"
  type        = string
}

variable "create_acm_certificate" {
  description = "Whether to create ACM certificates (set to false if using existing)"
  type        = bool
}

variable "existing_acm_certificate_arn" {
  description = "ARN of existing ACM certificate (required if create_acm_certificate is false)"
  type        = string
}

# =============================================================================
# Monitoring Variables
# =============================================================================

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
}
