resource "aws_lb" "app_alb" {
  name               = "${local.name}-${var.tags.Component}"
  internal           = true # If we keep internal = true, outside persons cannot see
  load_balancer_type = "application"
  security_groups    = [data.aws_ssm_parameter.app_alb_sg_id.value]
  subnets            = split(",", data.aws_ssm_parameter.private_subnet_ids.value) # App_ALB should be in minimum 2 subnets, and in ssm parameters subnets are in a one line with comma, so we split those to get the subnets in the form of list using split function
  tags = merge(
    var.common_tags,
    var.tags
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP" # Since it is internal communication

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Hi, This response is from APP ALB"
      status_code  = "200" # We just given 200 rule as a default, to test
    }
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  zone_name = var.zone_name
  records = [
    {
      name    = "*.app-${var.environment}"
      type    = "A"
      alias   = {
        name    = aws_lb.app_alb.dns_name
        zone_id = aws_lb.app_alb.zone_id
      }
    }
  ]
}


# You will get DNS name after creating App_ALB, and if you hit DNS you will get the website, what if i delete this App_ALB and create again ? Will that DNS name will be same ? NO! for that only we need to create a record for DNS using "*.app-${var.environment}" then how to use this in URL ? "catalogue..app-${var.environment}" or "cart.app-${var.environment}" etc.