# =============================================================================
# S3-CloudFront Module - Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "frontend_subdomain" {
  description = "Subdomain for the frontend"
  type        = string
  default     = "app"
}

variable "create_acm_certificate" {
  description = "Whether to create an ACM certificate"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
