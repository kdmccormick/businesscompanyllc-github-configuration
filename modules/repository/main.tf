## This module creates a GitHub repository, configured
## with some standard settings.

## Variable inputs are largely based upon:
## https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository
## with the addition of some organization-specific defaults and restrictions.

variable "name" {
  type        = string
  description = "The name of the repository (required)."
}

variable "description" {
  type        = string
  description = "The description of the repository (required)."
}

variable "required_status_checks" {
  type        = list(any)
  description = "Names of CI contexts that must pass for a PR to get a green build (required)."
}

variable "require_updated_branch_for_merge" {
  type        = bool
  description = "Whether PRs against the default branch must be fully-rebased for a green build to count (optional - defaults false)."
  default     = false
}

variable "template" {
  type = object({
    owner      = string
    repository = string
  })
  description = "Template repository to base this one upon (optional - defaults to empty repository)."
  default     = null
}

variable "visibility" {
  type        = string
  description = "Repository visibility (optional - defaults 'public')."
  default     = "public"
}

variable "homepage_url" {
  type        = string
  description = "The URL of the repository's homepage (optional)."
  default     = null
}

variable "has_issues" {
  type        = bool
  description = "Whether the repo has issues enabled (optional - default false)."
  default     = false
}

variable "has_projects" {
  type        = bool
  description = "Whether the repo has projects enabled (optional - defaults false)."
  default     = false
}

variable "has_wiki" {
  type        = bool
  description = "Whether the repo has the wiki enabled (optional - defaults false)."
  default     = false
}

variable "is_template" {
  type        = bool
  description = "Whether the repo is a template (optional - defaults false)."
  default     = false
}

variable "archived" {
  type        = bool
  description = "Whether the repo is archived (optional - defaults false)."
  default     = false
}

variable "topics" {
  type        = list(any)
  description = "List of repository topics (optional - defaults to empty)."
  default     = []
}

resource "github_repository" "this" {

  # Required parameters.
  name        = var.name
  description = var.description

  # Optional parameters.
  visibility   = var.visibility
  has_issues   = var.has_issues
  has_projects = var.has_projects
  has_wiki     = var.has_wiki
  is_template  = var.is_template
  archived     = var.archived
  topics       = var.topics

  # If a template repository was provided, assign it here.
  # If not, omit the 'template' block.
  # This is a weird Terraform-ism we need to do in order to pass
  # objects through modules.
  dynamic "template" {
    for_each = var.template == null ? [] : [var.template]
    content {
      owner      = template.value.owner
      repository = template.value.repository
    }
  }

  # Add an empty commit.
  # This ensures that the default branch is created, which allows
  # us to set branch protection rules below.
  auto_init = true

  # Allow any type of merge, but always delete branch on merge.
  allow_merge_commit     = true
  allow_rebase_merge     = true
  allow_squash_merge     = true
  allow_auto_merge       = true
  delete_branch_on_merge = true

  # Alert maintainers of security vulnerabilities.
  vulnerability_alerts = true

  # When repo is removed from terraform, actually destroy it!
  archive_on_destroy = false

  # If no template was provided, then we initialize an empty repo.
  # We prefer to use cookiecutters/templates for things like
  # .gitignore and LICENSE.
  gitignore_template = null
  license_template   = null
}


## Protect the default branch.
## We still use 'master' as the default branch across all repos for consistency.
## We may change to 'main' one day, but would do so all at once in a coordinated manner.

resource "github_branch" "master" {
  repository    = github_repository.this.name
  branch        = "master"
  source_branch = "master"
}

resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = github_branch.master.branch
}

resource "github_branch_protection" "protect_default_branch" {
  repository_id = github_repository.this.id
  pattern       = github_branch_default.this.branch

  # All PRs against default branch must pass CI to merge.
  required_status_checks {
    contexts = var.required_status_checks
    strict   = var.require_updated_branch_for_merge
  }

  # All PRs against default branch have review requirements.
  required_pull_request_reviews {

    # A new commit push doesn't invalidate existing approvals.
    # If this is abused, we could revisit it.
    dismiss_stale_reviews = false

    # If changes are requested but the review has been unresponsive,
    # the PR author may dismiss the review to unblock merging.
    # If this is abused, we could revisit it.
    restrict_dismissals = false

    # Any/all defined CODEOWNERs must approve.
    require_code_owner_reviews = true

    # Minimum 1 approval per any pull request.
    required_approving_review_count = 1
  }

  # Signed commits isn't something we require (yet?).
  require_signed_commits = false

  # Default branch may not be deleted or force-pushed.
  allows_deletions    = false
  allows_force_pushes = false

  # All of this applies to repo admins as well.
  enforce_admins = true
}


## Make repository name available as module output.

output "name" {
  value = github_repository.this.name
}
