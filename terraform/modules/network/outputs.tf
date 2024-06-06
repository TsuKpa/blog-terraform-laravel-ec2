output "public_subnet_ids" {
  value       = module.vpc.public_subnets
  description = "Public subnet ids"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnets
  description = "Private subnet ids"
}

output "vpc_id" {
    value = module.vpc.default_vpc_id
    description = "ID of the VPC"
}

output "sg_id" {
    value = module.sg-main.id
    description = "ID of the SG"
}