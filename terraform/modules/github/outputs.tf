output "github_ssh_url" {
    description = "Github ssh url"
    value = github_repository.github_repo.ssh_clone_url
}