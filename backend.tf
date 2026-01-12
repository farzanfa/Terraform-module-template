# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# Remote state storage using S3 with DynamoDB for state locking.
# Ensure the S3 bucket and DynamoDB table are created before running terraform init.
# =============================================================================

terraform {
  backend "s3" {
    bucket         = "password-manager-terraform-state"
    key            = "password-manager/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "password-manager-terraform-locks"

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
# 1. S3 Bucket:
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
# 2. DynamoDB Table:
#    aws dynamodb create-table \
#      --table-name password-manager-terraform-locks \
#      --attribute-definitions AttributeName=LockID,AttributeType=S \
#      --key-schema AttributeName=LockID,KeyType=HASH \
#      --billing-mode PAY_PER_REQUEST \
#      --region ap-south-1
# =============================================================================
