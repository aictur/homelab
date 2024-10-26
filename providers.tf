provider "github" {
  token = var.gh-token
}

provider "cloudflare" {
  api_token = var.cloudflare-token
}

provider "ssh" {
  debug_log = "ssh.log"
}

provider "helm" {
  debug = true
  kubernetes {
    config_path    = "kubeconfig"
    config_context = "default"
  }
}

provider "kubernetes" {
  config_path    = "./kubeconfig"
  config_context = "default"
}

provider "tailscale" {
  oauth_client_id = var.tailscale-client-id
  oauth_client_secret = var.tailscale-client-secret
  tailnet = var.tailscale-tailnet
}