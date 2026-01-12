# Password Manager Infrastructure

## Overview

This Terraform configuration provisions a complete AWS infrastructure for the Password Manager application, following AWS Well-Architected Framework principles and Terraform best practices.

## Architecture

```
                                    Internet
                                       │
                    ┌──────────────────┴──────────────────┐
                    │                                      │
                    ▼                                      ▼
             [CloudFront]                              [ALB]
           (React Frontend)                       (API Backend)
                    │                                      │
                    ▼                                      ▼
               [S3 Bucket]                        Private Subnet
            (Static Assets)                              │
                                                         ▼
                                              ┌──────────────────┐
                                              │   EC2 Instance   │
                                              │  ┌────────────┐  │
                                              │  │  Docker    │  │
                                              │  │  Backend   │  │
                                              │  ├────────────┤  │
                                              │  │PostgreSQL  │  │
                                              │  │   18       │  │
                                              │  ├────────────┤  │
                                              │  │  Valkey    │  │
                                              │  │(Redis 8)   │  │
                                              │  └────────────┘  │
                                              └──────────────────┘
```

## Infrastructure Components

| Component | Description |
|-----------|-------------|
| **VPC** | Custom VPC (10.0.0.0/16) with 2 public and 2 private subnets across 2 AZs |
| **EC2** | Amazon Linux 2023 instance running Docker, PostgreSQL 18, and Valkey |
| **ALB** | Application Load Balancer with HTTP-to-HTTPS redirect |
| **S3** | Static website hosting for React frontend |
| **CloudFront** | CDN for frontend with custom domain and SSL |
| **CloudWatch** | Log groups, metric alarms, and dashboard |

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.5.0
3. **S3 bucket** for Terraform state (see bootstrap instructions)
4. **DynamoDB table** for state locking

## Directory Structure

```
terraform/
├── backend.tf              # S3 backend configuration
├── main.tf                 # Module orchestration
├── outputs.tf              # Output definitions
├── providers.tf            # AWS provider configuration
├── variables.tf            # Variable definitions
├── environments/
│   └── dev.tfvars          # Development environment values
└── modules/
    ├── alb/                # Application Load Balancer
    ├── ec2/                # EC2 instance with user data
    ├── iam/                # IAM roles and policies
    ├── monitoring/         # CloudWatch resources
    ├── s3-cloudfront/      # S3 bucket and CloudFront
    └── vpc/                # VPC and networking
```

## Bootstrap State Backend

Before initializing Terraform, create the S3 bucket and DynamoDB table for state management:

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket password-manager-terraform-state \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket password-manager-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket password-manager-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name password-manager-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

## Getting Started

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Create/Select Workspace (Optional)

Use workspaces for environment isolation:

```bash
# Create workspace for dev
terraform workspace new dev

# Switch to workspace
terraform workspace select dev
```

### 3. Review Configuration

Update `environments/dev.tfvars` with your specific values:

- `key_pair_name`: Your EC2 key pair name
- `allowed_ssh_cidrs`: Your IP addresses for SSH access
- `domain_name`: Your custom domain

### 4. Plan and Apply

```bash
# Validate configuration
terraform validate

# Preview changes
terraform plan -var-file=environments/dev.tfvars

# Apply changes
terraform apply -var-file=environments/dev.tfvars
```

## State Management

This configuration uses a remote S3 backend with DynamoDB locking:

- **S3 Bucket**: `password-manager-terraform-state`
- **DynamoDB Table**: `password-manager-terraform-locks`
- **State Path**: `password-manager/terraform.tfstate`

Benefits:
- Team collaboration (shared state)
- State locking (prevents concurrent modifications)
- Versioning (state history and recovery)
- Encryption (data at rest)

## Post-Deployment Steps

### 1. Configure DNS Records

After deployment, create DNS records pointing to your infrastructure:

| Record Type | Name | Value |
|------------|------|-------|
| CNAME | `app-dev.example.com` | CloudFront distribution domain |
| CNAME | `api-dev.example.com` | ALB DNS name |

### 2. Validate ACM Certificate

If creating a new ACM certificate, add the DNS validation records output by Terraform to your DNS provider.

### 3. Deploy Frontend

Upload your React build to S3:

```bash
aws s3 sync ./build s3://$(terraform output -raw frontend_s3_bucket_name) --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

### 4. Deploy Backend

SSH into EC2 (via SSM Session Manager) and deploy your Docker container:

```bash
aws ssm start-session --target $(terraform output -raw ec2_instance_id)

# On the EC2 instance
cd /opt/password-manager
docker-compose up -d
```

## Security Considerations

- ✅ No hardcoded secrets (use SSM Parameter Store)
- ✅ IMDSv2 required on EC2
- ✅ S3 bucket public access blocked
- ✅ HTTPS enforced on ALB and CloudFront
- ✅ Security groups with least-privilege rules
- ✅ EBS volumes encrypted
- ✅ SSH access restricted by IP

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC identifier |
| `alb_dns_name` | ALB DNS name for backend |
| `cloudfront_distribution_url` | Frontend URL |
| `ec2_instance_id` | EC2 instance ID |
| `frontend_s3_bucket_name` | S3 bucket for frontend |

## Cost Optimization

Development environment uses:
- Single NAT Gateway (vs. one per AZ)
- Smaller EC2 instance type
- Basic CloudWatch monitoring
- CloudFront PriceClass_100 (US, Canada, Europe)

## Cleanup

To destroy all resources:

```bash
terraform destroy -var-file=environments/dev.tfvars
```

> ⚠️ **Warning**: This will delete all resources including data volumes. Ensure you have backups before destroying.

## License

MIT License - TerriffiMinds
