# =============================================================================
# Monitoring Module - Main Configuration
# =============================================================================

# -----------------------------------------------------------------------------
# CloudWatch Log Groups
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/password-manager/${var.environment}/backend"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-logs"
  })
}

resource "aws_cloudwatch_log_group" "system" {
  name              = "/password-manager/${var.environment}/system"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-system-logs"
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Metric Alarms
# -----------------------------------------------------------------------------

# EC2 CPU High Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU utilization is above 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = "${var.project_name}-${var.environment}"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ec2-cpu-high"
  })
}

# EC2 Status Check Failed Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  alarm_name          = "${var.project_name}-${var.environment}-ec2-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 status check failed"
  treat_missing_data  = "breaching"

  dimensions = {
    AutoScalingGroupName = "${var.project_name}-${var.environment}"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ec2-status-check"
  })
}

# ALB Healthy Host Count Alarm
resource "aws_cloudwatch_metric_alarm" "alb_healthy_hosts" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "No healthy hosts behind ALB"
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = "${var.project_name}-${var.environment}"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb-healthy-hosts"
  })
}

# ALB 5XX Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB 5XX error count is above threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = "${var.project_name}-${var.environment}"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb-5xx-errors"
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Dashboard
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EC2 CPU Utilization"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${var.project_name}-${var.environment}"]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EC2 Memory Utilization"
          region = data.aws_region.current.name
          metrics = [
            ["PasswordManager/${var.environment}", "mem_used_percent"]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ALB Request Count"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${var.project_name}-${var.environment}"]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ALB Response Time"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${var.project_name}-${var.environment}"]
          ]
          period = 60
          stat   = "Average"
        }
      }
    ]
  })
}

data "aws_region" "current" {}
