resource "github_repository" "github_repo" {
  name        = var.github_repo_name
  description = var.github_repo_description
  visibility  = "private"
  auto_init   = true
}

locals {
  other_branchs = [for k, v in var.github_branchs: v]
  default_branch_list = [for k, v in var.github_branchs: v if v["is_default"] == true]
  default_branch = length(local.default_branch_list) > 0 ? element(local.default_branch_list, 0)["name"] : "develop"
}

resource "github_branch" "github_branchs" {
  count = length(local.other_branchs)
  repository = github_repository.github_repo.name
  source_branch = "master"
  branch = local.other_branchs[count.index]["name"]
  depends_on = [ github_repository.github_repo ]
}

resource "github_branch_default" "github_branch_default"{
  count = length(local.default_branch_list)
  repository = github_repository.github_repo.name
  branch     = local.default_branch
  depends_on = [ github_branch.github_branchs ]
}