# =============================================================================
# Password Manager Infrastructure - Main Configuration
# =============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
    },
    var.custom_tags
  )
}

# =============================================================================
# Data Sources
# =============================================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# =============================================================================
# VPC Module
# =============================================================================

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  allowed_ssh_cidrs    = var.allowed_ssh_cidrs
  backend_port         = var.backend_port

  tags = local.common_tags
}

# =============================================================================
# IAM Module
# =============================================================================

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id

  tags = local.common_tags
}

# =============================================================================
# Monitoring Module
# =============================================================================

module "monitoring" {
  source = "./modules/monitoring"

  project_name       = var.project_name
  environment        = var.environment
  log_retention_days = var.log_retention_days

  tags = local.common_tags
}

# =============================================================================
# ECR Module
# =============================================================================

module "ecr" {
  source = "./modules/ecr"

  project_name               = var.project_name
  environment                = var.environment
  image_tag_mutability       = var.ecr_image_tag_mutability
  scan_on_push               = var.ecr_scan_on_push
  image_count_to_keep        = var.ecr_image_count_to_keep
  untagged_image_expiry_days = var.ecr_untagged_image_expiry_days

  tags = local.common_tags
}

# =============================================================================
# EC2 Module
# =============================================================================

module "ec2" {
  source = "./modules/ec2"

  project_name               = var.project_name
  environment                = var.environment
  instance_type              = var.instance_type
  key_pair_name              = var.key_pair_name
  subnet_id                  = module.vpc.private_subnet_ids[0]
  security_group_ids         = [module.vpc.ec2_security_group_id]
  iam_instance_profile_name  = module.iam.ec2_instance_profile_name
  root_volume_size           = var.root_volume_size
  enable_detailed_monitoring = var.enable_detailed_monitoring
  backend_log_group_name     = module.monitoring.backend_log_group_name
  system_log_group_name      = module.monitoring.system_log_group_name
  aws_region                 = var.aws_region
  ecr_repository_url         = module.ecr.repository_url

  tags = local.common_tags

  depends_on = [module.vpc, module.iam, module.monitoring, module.ecr]
}

# =============================================================================
# Bastion Module
# =============================================================================

module "bastion" {
  source = "./modules/bastion"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  instance_type     = var.bastion_instance_type
  key_pair_name     = var.key_pair_name
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  assign_elastic_ip = var.bastion_assign_elastic_ip

  tags = local.common_tags

  depends_on = [module.vpc]
}

# =============================================================================
# Security Group Rule: SSH from Bastion to Private EC2
# =============================================================================

resource "aws_security_group_rule" "bastion_to_ec2_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = module.vpc.ec2_security_group_id
  source_security_group_id = module.bastion.security_group_id
  description              = "SSH from Bastion host"
}

# =============================================================================
# ALB Module
# =============================================================================

module "alb" {
  source = "./modules/alb"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_id  = module.vpc.alb_security_group_id
  target_instance_id = module.ec2.instance_id
  backend_port       = var.backend_port
  health_check_path  = var.health_check_path
  certificate_arn    = var.create_acm_certificate ? module.s3_cloudfront.acm_certificate_arn : var.existing_acm_certificate_arn

  tags = local.common_tags

  depends_on = [module.vpc, module.ec2]
}

# =============================================================================
# S3 + CloudFront Module
# =============================================================================

module "s3_cloudfront" {
  source = "./modules/s3-cloudfront"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project_name           = var.project_name
  environment            = var.environment
  domain_name            = var.domain_name
  frontend_subdomain     = var.frontend_subdomain
  create_acm_certificate = var.create_acm_certificate

  tags = local.common_tags
}
