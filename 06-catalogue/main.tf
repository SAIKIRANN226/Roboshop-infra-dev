resource "aws_lb_target_group" "catalogue" {
  name     = "${local.name}-${var.tags.Component}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
  deregistration_delay = 60
  health_check {
      healthy_threshold   = 2
      interval            = 10
      unhealthy_threshold = 3
      timeout             = 5
      path                = "/health"
      port                = 8080
      matcher = "200-299"
  }
}

module "catalogue" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.centos8.id
  name                   = "${local.name}-${var.tags.Component}-ami"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]
  subnet_id              = element(split(",", data.aws_ssm_parameter.private_subnet_ids.value), 0)
  iam_instance_profile = "ShellScriptRoleForRoboshop"
  tags = merge(
    var.common_tags,
    var.tags
  )
}

resource "null_resource" "catalogue" {
  triggers = {
    instance_id = module.catalogue.id
  }

  connection {
    host = module.catalogue.private_ip
    type = "ssh"
    user = "centos"
    password = "DevOps321"
  }

  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo sh /tmp/bootstrap.sh catalogue dev"
    ]
  }
}

resource "aws_ec2_instance_state" "catalogue" {
  instance_id = module.catalogue.id
  state       = "stopped"
  depends_on = [ null_resource.catalogue ]
}

resource "aws_ami_from_instance" "catalogue" {
  name               = "${local.name}-${var.tags.Component}-${local.current_time}"
  source_instance_id = module.catalogue.id
  depends_on = [ aws_ec2_instance_state.catalogue ]
}

resource "null_resource" "catalogue_delete" {
  triggers = {
    instance_id = module.catalogue.id
  }

  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${module.catalogue.id}"
  }
  depends_on = [ aws_ami_from_instance.catalogue]
}

resource "aws_launch_template" "catalogue" { # Hiring template to hire the employees or instances
  name = "${local.name}-${var.tags.Component}"
  image_id = aws_ami_from_instance.catalogue.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"
  update_default_version = true
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name}-${var.tags.Component}"
    }
  }

}

resource "aws_autoscaling_group" "catalogue" { # HR to auto-scale the instances or employees using above Launch template
  name                      = "${local.name}-${var.tags.Component}"
  max_size                  = 10 # Maximum instances we put 10
  min_size                  = 1 # Minimum instances we put 1
  health_check_grace_period = 60
  health_check_type         = "ELB"
  desired_capacity          = 2
  vpc_zone_identifier       = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
  target_group_arns = [ aws_lb_target_group.catalogue.arn ] # Where this instances should be placed ?

  launch_template {
    id      = aws_launch_template.catalogue.id
    version = aws_launch_template.catalogue.latest_version
  }

  instance_refresh { # Nothing but rolling update
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50 # That means minimum half your instances should be running and healthy
    }
    triggers = ["launch_template"] # Whenever the launch-template is updated then auto-scaling will automatically trigger and refresh this
  }

  tag {
    key                 = "Name"
    value               = "${local.name}-${var.tags.Component}"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_lb_listener_rule" "catalogue" {
  listener_arn = data.aws_ssm_parameter.app_alb_listener_arn.value
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn
  }

  condition {
    host_header {
      values = ["${var.tags.Component}.app-${var.environment}.${var.zone_name}"]
    }
  }
}

resource "aws_autoscaling_policy" "catalogue" {
  autoscaling_group_name = aws_autoscaling_group.catalogue.name
  name                   = "${local.name}-${var.tags.Component}"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 5.0 # Generally it will be 75-80
  }
}


# Overview of the above code
# 1. Create catalogue target group
# 2. Create one instance
# 3. Provision instance with ansible or shell
# 4. Stop the instance
# 5. Take the AMI
# 6. Delete the instance
# 7. Now create Launch template with the AMI
# 8. If we give this Launch template to the auto-scaling, it will create the instances depending up on the traffic
# 9. If you are not aware of what options to give in the code, just try to create a sample resource in the aws console, and see what options are required, and same options put in the code by taking from the google, do for every resource if you are not aware of