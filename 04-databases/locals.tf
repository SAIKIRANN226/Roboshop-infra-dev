locals {
  ec2_name = "${var.project_name}-${var.environment}"
  database_subnet_id = element(split(",", data.aws_ssm_parameter.database_subnet_ids.value), 0) # We are just keeping all resources in 1a subnet
}