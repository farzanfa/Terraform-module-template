# =============================================================================
# IAM Module - Custom Policies
# =============================================================================

# -----------------------------------------------------------------------------
# CloudWatch Logs Policy
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.project_name}-${var.environment}-cloudwatch-logs-policy"
  description = "Allows EC2 to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLogGroupOperations"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/password-manager/${var.environment}/*",
          "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/password-manager/${var.environment}/*:*"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cloudwatch-logs-policy"
  })
}

# -----------------------------------------------------------------------------
# SSM Parameter Store Read Policy
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "ssm_read" {
  name        = "${var.project_name}-${var.environment}-ssm-read-policy"
  description = "Allows EC2 to read parameters from SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSSMParameterRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/password-manager/${var.environment}/*"
        ]
      },
      {
        Sid    = "AllowKMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ssm-read-policy"
  })
}

# -----------------------------------------------------------------------------
# ECR Pull Policy
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "ecr_pull" {
  name        = "${var.project_name}-${var.environment}-ecr-pull-policy"
  description = "Allows EC2 to pull images from ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowECRPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = [
          "arn:aws:ecr:${var.aws_region}:${var.account_id}:repository/${var.project_name}-${var.environment}-*"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecr-pull-policy"
  })
}
