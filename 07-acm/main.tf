resource "aws_acm_certificate" "daws76s" {
  domain_name       = "*.daws76s.online" # We are taking certificate for this | The code from line 15-30 will take records from the certificate and create in the hosted zone in line 15-30
  validation_method = "DNS"

  tags = merge(
    var.tags,
    var.common_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "daws76s" { # Validation is nothing but creating some records in your hosted zone,obviously ownership is with us then we need to click on validation 
  for_each = {
    for dvo in aws_acm_certificate.daws76s.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 1
  type            = each.value.type
  zone_id         = data.aws_route53_zone.daws76s.zone_id
}

resource "aws_acm_certificate_validation" "daws76s" { # We need to validate after creating records
  certificate_arn         = aws_acm_certificate.daws76s.arn
  validation_record_fqdns = [for record in aws_route53_record.daws76s : record.fqdn]
}