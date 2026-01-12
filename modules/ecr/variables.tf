# =============================================================================
# ECR Module - Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
}

variable "image_count_to_keep" {
  description = "Number of tagged images to keep"
  type        = number
}

variable "untagged_image_expiry_days" {
  description = "Days after which untagged images expire"
  type        = number
}

variable "allow_push_from_account_ids" {
  description = "List of AWS account IDs allowed to push images (optional)"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
