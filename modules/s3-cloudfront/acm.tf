# =============================================================================
# S3-CloudFront Module - ACM Certificate (us-east-1)
# =============================================================================

# -----------------------------------------------------------------------------
# ACM Certificate for CloudFront (must be in us-east-1)
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "frontend" {
  count = var.create_acm_certificate ? 1 : 0

  provider = aws.us_east_1

  domain_name       = "${var.frontend_subdomain}.${var.domain_name}"
  validation_method = "DNS"

  subject_alternative_names = [
    var.domain_name
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-frontend-cert"
  })
}

# -----------------------------------------------------------------------------
# ACM Certificate Validation
# -----------------------------------------------------------------------------

# NOTE: This resource creates DNS validation records.
# You will need to manually add these records to your DNS provider,
# or integrate with Route53 if using AWS DNS.

resource "aws_acm_certificate_validation" "frontend" {
  count = var.create_acm_certificate ? 1 : 0

  provider = aws.us_east_1

  certificate_arn = aws_acm_certificate.frontend[0].arn

  # If using Route53, uncomment and configure the following:
  # validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "45m"
  }
}

# -----------------------------------------------------------------------------
# Output DNS Validation Records (for manual DNS configuration)
# -----------------------------------------------------------------------------

# These outputs help you create the required DNS records for certificate validation.
# Add these records to your DNS provider before running terraform apply.

output "acm_validation_records" {
  description = "DNS records required for ACM certificate validation"
  value = var.create_acm_certificate ? {
    for dvo in aws_acm_certificate.frontend[0].domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : {}
}
