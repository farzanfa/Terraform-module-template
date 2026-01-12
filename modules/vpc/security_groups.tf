# =============================================================================
# VPC Module - Security Groups
# =============================================================================

# -----------------------------------------------------------------------------
# ALB Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # HTTP ingress
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS ingress
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress to EC2 backend
  egress {
    description     = "Backend traffic to EC2"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  })
}

# -----------------------------------------------------------------------------
# EC2 Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Security group for EC2 instance running backend, PostgreSQL, and Valkey"
  vpc_id      = aws_vpc.main.id

  # Backend port from ALB
  ingress {
    description = "Backend traffic from ALB"
    from_port   = var.backend_port
    to_port     = var.backend_port
    protocol    = "tcp"
    self        = false
    # Will be updated after ALB SG is created
  }

  # SSH access (restricted by IP)
  dynamic "ingress" {
    for_each = length(var.allowed_ssh_cidrs) > 0 ? [1] : []
    content {
      description = "SSH from allowed IPs"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidrs
    }
  }

  # PostgreSQL internal (localhost only - self reference for future scaling)
  ingress {
    description = "PostgreSQL internal"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
  }

  # Valkey internal (localhost only - self reference for future scaling)
  ingress {
    description = "Valkey internal"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    self        = true
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ec2-sg"
  })
}

# -----------------------------------------------------------------------------
# Security Group Rule: ALB to EC2 (added after both SGs exist)
# -----------------------------------------------------------------------------

resource "aws_security_group_rule" "alb_to_ec2" {
  type                     = "ingress"
  from_port                = var.backend_port
  to_port                  = var.backend_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Backend traffic from ALB"
}
