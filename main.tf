
# Top-level Terraform configuration.
# Cannot be parameterized.
terraform {

  # Require the GitHub-maintained GitHub-Terraform provider.
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }

  # Link with our organization and workspace on Terraform Cloud.
  backend "remote" {
    # Organization from app.terraform.io
    organization = "businesscompanyllc"

    workspaces {
      # Workspace from app.terraform.io
      name = "businesscompanyllc-github"
    }
  }
}

variable "github_organization" {
  type        = string
  default     = "businesscompanyllc"
  description = "The GitHub organization on which this repository will act."
}

# Note: GITHUB_TOKEN must be provided as an environment variable.

variable "github_configuration_bot_username" {
  type        = string
  description = "The username of the bot that applies github-configuration PRs."
  default     = "businesscompanyllc-gh-config-bot"
}

variable "test_username_0" {
  type        = string
  description = "The owner username."
}

variable "test_username_1" {
  type        = string
  description = "A username to test with."
}

variable "test_username_2" {
  type        = string
  description = "A second username to test with."
}

# Use the GitHub-Terraform provider.
# The following two environment variables must be provided:
#  * GITHUB_TOKEN: personal access token of GH account used to apply this.
#  * GITHUB_OWNER: user or organization to create resources under.
provider "github" {
}

# Let the org management team push to this repo.
#resource "github_team_repository" "organization_managers_write_to_gh_config" {
#  team_id    = github_team.organization_managers.id
#  repository = github_repository.github_configuration.name
#  permission = "push"
#}

# Add user 0 to our GH organization as owner.
resource "github_membership" "user_0" {
  username = var.test_username_0
  role     = "admin"
}

# Add user 1 to our GH organization as member.
resource "github_membership" "user_1" {
  username = var.test_username_1
  role     = "member"
}

resource "github_team" "organization_managers" {
  name        = "organization-managers"
  description = "People who can manager our GH org by merging to github-configuration."
  privacy     = "closed"
}

resource "github_team_membership" "membership_for_user_1" {
  team_id  = github_team.organization_managers.id
  username = github_membership.user_1.username
  role     = "member"
}
