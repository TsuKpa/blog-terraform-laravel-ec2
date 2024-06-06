###############################
# Github variables
###############################

variable "github_token" {
  type        = string
  description = "Github token for create repository"
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

variable "github_branchs" {
  type = list(object({
    name       = string
    is_default = bool
    action     = bool
  }))

  default = [
    {
      name       = "develop"
      is_default = false
      action     = true
    }, 
    {
      name       = "staging"
      is_default = false
      action     = false
    }
  ]
  description = "Github default branch trigger action deploy"
}
