# =============================================================================
# Common Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project used for resource naming and tagging"
  type        = string
  default     = "password-manager"
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
  default     = "ap-south-1"
}

variable "owner" {
  description = "Owner of the infrastructure for tagging"
  type        = string
  default     = "DevOps Team"
}

variable "cost_center" {
  description = "Cost center for billing purposes"
  type        = string
  default     = "Engineering"
}

# =============================================================================
# Network Variables
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for subnet deployment"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

# =============================================================================
# EC2 Variables
# =============================================================================

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []
  sensitive   = true
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 30
}

variable "data_volume_size" {
  description = "Size of the data EBS volume in GB for PostgreSQL and Valkey"
  type        = number
  default     = 50
}

# =============================================================================
# Application Variables
# =============================================================================

variable "backend_port" {
  description = "Port the backend application listens on"
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Health check path for the load balancer"
  type        = string
  default     = "/health"
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
  default     = "app"
}

variable "api_subdomain" {
  description = "Subdomain for the API (e.g., 'api' for api.example.com)"
  type        = string
  default     = "api"
}

variable "create_acm_certificate" {
  description = "Whether to create ACM certificates (set to false if using existing certificates)"
  type        = bool
  default     = true
}

variable "existing_acm_certificate_arn" {
  description = "ARN of existing ACM certificate (required if create_acm_certificate is false)"
  type        = string
  default     = ""
}

# =============================================================================
# Monitoring Variables
# =============================================================================

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for EC2"
  type        = bool
  default     = false
}

# =============================================================================
# NAT Gateway Variables
# =============================================================================

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs (cost optimization for non-prod)"
  type        = bool
  default     = true
}
