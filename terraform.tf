terraform {
  required_version = ">= 0.13"

  required_providers {
    github = {
      source = "integrations/github"
      version = "6.3.1"
    }
    ssh = {
      source = "loafoe/ssh"
      version = "2.7.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.16.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.33.0"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}