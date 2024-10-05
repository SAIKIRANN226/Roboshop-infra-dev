resource "aws_lb" "app_alb" {
  name               = "${local.name}-${var.tags.Component}" # We want name to be roboshop-dev-app-alb
  internal           = true # Because it is internal load balancer
  load_balancer_type = "application"
  security_groups    = [data.aws_ssm_parameter.app_alb_sg_id.value] # We created app-alb SG and exported to ssm parameter,so this app-alb should accpet connections from vpn since it is internal and same created in SG main.tf
  subnets            = split(",", data.aws_ssm_parameter.private_subnet_ids.value) # In parameter store it is in the form of same line with , but we need to split this 

  tags = merge(
    var.common_tags,
    var.tags
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response" # Fixed response is for just testing,we added a default for testing purpose if anybody hits the URL give them default response

    fixed_response {
      content_type = "text/plain"
      message_body = "Hi, This response is from APP ALB"
      status_code  = "200"
    }
  }
}

# Listener is created for app-alb on http:80, there you can see a DNS name which is given by aws to the app-alb,the SG of app-alb is listening from vpn so create SG of app-alb in 02-sg,if we turn-off vpn then it will not listen,when you delete and create then DNS name will be changed,so for that we need to create DNS record like host path 

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