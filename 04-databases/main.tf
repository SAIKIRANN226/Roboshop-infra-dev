module "mongodb" {
  source = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.centos8.id
  name = "${local.ec2_name}-mongodb"
  instance_type = "t3.small"
  vpc_security_group_ids = [data.aws_ssm_parameter.mongodb_sg_id.value]
  subnet_id = local.database_subnet_id
  tags = merge(
    var.common_tags,
    {
      Component = "mongodb"
    },
    {
      Name = "${local.ec2_name}-mongodb"
    }
  )
}

resource "null_resource" "mongodb" { # You can attach local-exec or remote-exec provisioners to run commands after a resource is created, in this case we are creating mongodb instance above
  triggers = {
    instance_id = module.mongodb.id
  }
  
  connection {
    host = module.mongodb.private_ip
    type = "ssh"
    user = "centos"
    password = "DevOps321"
  }

  provisioner "file" { # Before running the remote-exec, we need to copy the boostrap file from local to in the remote-server
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo sh /tmp/bootstrap.sh mongodb dev" # We dont get root access by default in provisioners, but we get in "user-data"
    ]
  }
}

module "redis" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.centos8.id
  name                   = "${local.ec2_name}-redis"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.redis_sg_id.value]
  subnet_id              = local.database_subnet_id
  tags = merge(
    var.common_tags,
    {
      Component = "redis"
    },
    {
      Name = "${local.ec2_name}-redis"
    }
  )
}

resource "null_resource" "redis" {
  triggers = {
    instance_id = module.redis.id
  }

  connection {
    host = module.redis.private_ip
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
      "sudo sh /tmp/bootstrap.sh redis dev"
    ]
  }
}

module "mysql" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.centos8.id
  name                   = "${local.ec2_name}-mysql"
  instance_type          = "t3.small"
  vpc_security_group_ids = [data.aws_ssm_parameter.mysql_sg_id.value]
  subnet_id              = local.database_subnet_id
  iam_instance_profile = "ShellScriptRoleForRoboshop" # Role, why we used this ? because we have one password that is roboshop@1 to get this, we used role and used lookup function for this password in ansible roles, because here ansible is provisioning the install, so ansible should get this password from the roles
  tags = merge(
    var.common_tags,
    {
      Component = "mysql"
    },
    {
      Name = "${local.ec2_name}-mysql"
    }
  )
}

resource "null_resource" "mysql" {
  triggers = {
    instance_id = module.mysql.id
  }

  connection {
    host = module.mysql.private_ip
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
      "sudo sh /tmp/bootstrap.sh mysql dev"
    ]
  }
}

module "rabbitmq" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.centos8.id
  name                   = "${local.ec2_name}-rabbitmq"
  instance_type          = "t3.small"
  vpc_security_group_ids = [data.aws_ssm_parameter.rabbitmq_sg_id.value]
  subnet_id              = local.database_subnet_id
  iam_instance_profile = "ShellScriptRoleForRoboshop" # In rabitmq also we have one username and password, siva used community module, here we are going through manually like using command (or) shell, we dont have idempotency in command or shell, so we need to use the modules, why community modules are used here ? because we dont have in official modules, so we are going for community modules, you can seach in google like "ansible rabitmq user" we can see "community.rabitmq.rabitmq_user:" but siva used command module in the roles, we can use that also but no idempotency
  tags = merge(
    var.common_tags,
    {
      Component = "rabbitmq"
    },
    {
      Name = "${local.ec2_name}-rabbitmq"
    }
  )
}

resource "null_resource" "rabbitmq" {
  triggers = {
    instance_id = module.rabbitmq.id
  }

  connection {
    host = module.rabbitmq.private_ip
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
      "sudo sh /tmp/bootstrap.sh rabbitmq dev"
    ]
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  zone_name = var.zone_name
  records = [
    {
      name    = "mongodb-dev"
      type    = "A"
      ttl     = 1
      records = [
        module.mongodb.private_ip,
      ]
    },
    {
      name    = "redis-dev"
      type    = "A"
      ttl     = 1
      records = [
        module.redis.private_ip,
      ]
    },
    {
      name    = "mysql-dev"
      type    = "A"
      ttl     = 1
      records = [
        module.mysql.private_ip,
      ]
    },
    {
      name    = "rabbitmq-dev"
      type    = "A"
      ttl     = 1
      records = [
        module.rabbitmq.private_ip,
      ]
    },
  ]
}