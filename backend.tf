# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# Remote state storage using S3 with native S3 lock file for state locking.
# Ensure the S3 bucket is created before running terraform init.
# =============================================================================

terraform {
  backend "s3" {
    bucket       = "password-manager-terraform-state"
    key          = "password-manager/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true

    # Workspace-aware state paths
    # State files will be stored as: password-manager/{workspace}/terraform.tfstate
  }
}

# =============================================================================
# Backend Bootstrap Resources (for reference - create manually or via separate config)
# =============================================================================
# 
# The following resources must exist before initializing Terraform:
#
# S3 Bucket:
#    aws s3api create-bucket \
#      --bucket password-manager-terraform-state \
#      --region ap-south-1 \
#      --create-bucket-configuration LocationConstraint=ap-south-1
#
#    aws s3api put-bucket-versioning \
#      --bucket password-manager-terraform-state \
#      --versioning-configuration Status=Enabled
#
#    aws s3api put-bucket-encryption \
#      --bucket password-manager-terraform-state \
#      --server-side-encryption-configuration '{
#        "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
#      }'
#
# Note: DynamoDB table is no longer required when using use_lockfile = true.
# The lock file (.terraform.lock.hcl) is stored alongside the state file in S3.
# =============================================================================
