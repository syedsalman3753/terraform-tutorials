terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.2.1"
    }
  }
}

provider "github" {
  token = ""
}

resource "github_repository" "test_1" {
  name        = "test1"
  description = "My awesome codebase test1"
  visibility  = "public"
  auto_init   = true
}

resource "github_repository" "test_2" {
  name        = "test2"
  description = "xxxxxxxxxxxxxx My awesome codebase test2"
  visibility  = "public"
  auto_init   = true
}

output "repo-url" {
  value = github_repository.test_2.html_url
}