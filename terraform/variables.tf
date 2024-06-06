###############################
# Github token
###############################
variable "github_token" {
  type        = string
  description = "Github token for create repository"
  sensitive = true
}

variable "github_owner" {
  type        = string
  description = "Github owner"
  sensitive = true
}

variable "github_repo_name" {
  type        = string
  description = "Github repository name"
}

variable "github_repo_description" {
  type        = string
  description = "Github repository description"
}

###############################
# AWS Region
###############################
variable "region" {
  type        = string
  description = "Region"
  default     = "ap-southeast-1"
}

###############################
# EC2
###############################

variable "instance_type" {
  type        = string
  description = "Name of the instance type"
  default     = "t2.micro"
}

variable "key_name" {
  type        = string
  description = "Name of the key pair use to ssh"
  default     = "myec2-keypair"
}

###############################
# VPC, subnet
###############################

variable "vpc_name" {
  type        = string
  description = "Name for the VPC"
}