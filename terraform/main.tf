# module "network" {
#   source          = "./modules/network"
#   vpc_name        = var.vpc_name
# }

# module "web_server" {
#   source      = "./modules/ec2"
#   subnet_id = module.network.public_subnet_ids[0]
#   sg_id = module.network.sg_id
#   instance_type = var.instance_type
#   key_name = var.key_name
#   depends_on = [ module.network ]
# }

module "repository" {
  source                  = "./modules/github"
  github_token            = var.github_token
  github_repo_name        = var.github_repo_name
  github_repo_description = var.github_repo_description
}
