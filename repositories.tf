
module "repository_github_configuration" {
  source                 = "./modules/repository"
  name                   = "github-configuration"
  description            = "GitHub organization configuration-as-code, includinging permissions, teams, and repositories."
  required_status_checks = ["Terraform"]
}

module "repository_core_platform" {
  source                 = "./modules/repository"
  name                   = "core-platform"
  description            = "Our highly extensible, self-contained, micro-service, mono-repo, polyglot, no-code, yes-farms, yes-food, platform core. Now available in Python 2.6."
  required_status_checks = []
}

module "repository_innovation_plugin" {
  source                           = "./modules/repository"
  name                             = "innovation-plugin"
  description                      = "A core platform plugin to inspire synergistic acceleration alignment"
  required_status_checks           = []
  require_updated_branch_for_merge = true
  homepage_url                     = "http://example.com/innovatify"
}

module "repository_spa_frontend" {
  source                           = "./modules/repository"
  name                             = "spa-frontend"
  description                      = "Kick back and relax, it's a single-page app."
  required_status_checks           = []
  require_updated_branch_for_merge = true
  template = {
    repository = "react-boilerplate"
    owner      = "react-boilerplate"
  }
}
