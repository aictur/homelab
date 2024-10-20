locals {
  dominios = jsondecode(file("domains.json"))
}
resource "time_static" "restarted_at" {}

# Creamos el tunel de cloudflare
resource "cloudflare_zero_trust_tunnel_cloudflared" "cloudflare-tunnel" {
  account_id = var.cloudflare-account-id
  name       = "grx01 kubernetes"
  tunnel_secret = sensitive(base64sha256(var.cloudflare-tunnel-secret))
}

# Namespace de k8s para cloudflared
resource "kubernetes_namespace" "cloudflared-namespace" {
  metadata {
    name = "cloudflared"
  }
}

# Secreto para la configuracion de cloudflared
resource "kubernetes_secret" "cloudflared-secrets" {
  metadata {
    name = "tunnel-credentials"
    namespace = "cloudflared"
  }
  data = {
    "credentials.json" =jsonencode({
      AccountTag = var.cloudflare-account-id,
      TunnelSecret = base64sha256(var.cloudflare-tunnel-secret),
      TunnelID = cloudflare_zero_trust_tunnel_cloudflared.cloudflare-tunnel.id
    })
  }
}

# Configuracion de cloudflared
resource "kubernetes_config_map" "cloudflared-config" {
  metadata {
    name = "cloudflared-config"
    namespace = "cloudflared"
  }
  data = {
    "config.yaml" = yamlencode({
      tunnel = "homelab-grx01-k8s"
      credentials-file = "/etc/cloudflared/creds/credentials.json"
      metrics = "0.0.0.0:2000"
      no-autoupdate = true
      ingress = flatten([
        [for dominio in local.dominios : {
          hostname = dominio.value
          service = dominio.service
        } if dominio.tunnel],
        {service = "http_status:404"}
      ])
    })
  }
}
# Desplegamos cloudflared
resource "kubernetes_manifest" "cloudflared" {
  manifest = yamldecode(file("./kubernetes/cloudflared.yaml"))
}
