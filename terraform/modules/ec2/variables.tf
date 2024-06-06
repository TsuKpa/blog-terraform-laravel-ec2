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

variable "subnet_id" {
  type = string
  description = "The subnet id of instance"
}

variable "sg_id" {
  type = string
  description = "The security group id of instance"
}

###############################
# EC2 AutoScaling Group
###############################

variable "enable_auto_scaling_group" {
  type = bool
  default = true
  description = "Enable/disable auto scaling group"
}

variable "max_size" {
  type = number
  default = 2
  description = "Max instances auto scaling group"
}

variable "min_size" {
  type = number
  default = 1
  description = "Min instance auto scaling group"
}

variable "desired_capacity" {
  type = number
  default = 2
  description = "Desired instances auto scaling group"
}

