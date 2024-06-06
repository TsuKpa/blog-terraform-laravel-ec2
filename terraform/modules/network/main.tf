data "aws_region" "current" {}

locals {
  cidr            = "10.0.0.0/16"
  partition       = cidrsubnets(local.cidr, 4, 4)
  private_subnets = local.partition[0]
  public_subnets  = local.partition[1]
  azs             = formatlist("${data.aws_region.current.name}%s", ["a", "b"])
  ports = {
    ssh = 22
    http = 80
    https = 443
  }
  anywhere_cidr = "0.0.0.0/0"
}

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  name            = var.vpc_name
  azs             = local.azs
  cidr            = local.cidr
  private_subnets = [local.private_subnets]
  public_subnets  = [local.public_subnets]
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


module "sg-main" {
  source     = "cloudposse/security-group/aws"
  version    = "2.2.0"
  depends_on = [module.vpc]

  # Security Group names must be unique within a VPC.
  # This module follows Cloud Posse naming conventions and generates the name
  # based on the inputs to the null-label module, which means you cannot
  # reuse the label as-is for more than one security group in the VPC.
  #
  # Here we add an attribute to give the security group a unique name.
  attributes = ["primary-sg"]

  # Allow unlimited egress
  allow_all_egress = true

  rules = [
    {
      key         = "ssh"
      type        = "ingress"
      from_port   = local.ports["ssh"]
      to_port     = local.ports["ssh"]
      protocol    = "tcp"
      cidr_blocks = [local.anywhere_cidr]
      self        = null # preferable to self = false
      description = "Allow SSH from anywhere"
    },
    {
      key         = "HTTP"
      type        = "ingress"
      from_port   = local.ports["http"]
      to_port     = local.ports["http"]
      protocol    = "tcp"
      cidr_blocks = [local.anywhere_cidr]
      self        = null
      description = "Allow HTTP from anywhere"
    }
  ]

  vpc_id = module.vpc.vpc_id
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
