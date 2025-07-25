resource "aws_ssm_parameter" "acm_certificate_arn" {
  name  = "/${var.project_name}/${var.environment}/acm_certificate_arn"
  type  = "String"
  value = aws_acm_certificate.daws76s.arn
}


# Nothing but exporting created certificate in SSM Parameter