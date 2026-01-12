# =============================================================================
# Monitoring Module - Outputs
# =============================================================================

output "backend_log_group_name" {
  description = "Name of the backend CloudWatch log group"
  value       = aws_cloudwatch_log_group.backend.name
}

output "backend_log_group_arn" {
  description = "ARN of the backend CloudWatch log group"
  value       = aws_cloudwatch_log_group.backend.arn
}

output "system_log_group_name" {
  description = "Name of the system CloudWatch log group"
  value       = aws_cloudwatch_log_group.system.name
}

output "system_log_group_arn" {
  description = "ARN of the system CloudWatch log group"
  value       = aws_cloudwatch_log_group.system.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "cpu_alarm_arn" {
  description = "ARN of the EC2 CPU high alarm"
  value       = aws_cloudwatch_metric_alarm.ec2_cpu_high.arn
}
