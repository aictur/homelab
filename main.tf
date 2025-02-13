resource "github_repository" "homelab-repo" {
  auto_init            = false
  description          = "🧑‍💻 My personal infrastructure using Kubernetes, Terraform, Cloudflare and more"
  name                 = var.gh-repo-name
  visibility           = "public"
  vulnerability_alerts = true
}

resource "github_repository_ruleset" "not-to-main" {
  name        = "Not to main"
  repository  = github_repository.homelab-repo.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  bypass_actors {
    actor_id    = 5
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  rules {
    deletion         = true
    non_fast_forward = true
    pull_request {
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = true
      require_last_push_approval        = true
      required_approving_review_count   = 1
      required_review_thread_resolution = false
    }
  }
}

# resource "github_repository_environment" "production" {
#   environment         = "production"
#   repository          = github_repository.homelab-repo.name
#   prevent_self_review = false
#   reviewers {
#     users = [data.github_user.current.id]
#   }
#   deployment_branch_policy {
#     protected_branches     = true
#     custom_branch_policies = false
#   }
# }

# resource "github_actions_environment_secret" "gh-ts-oauth-client-id" {
#   repository      = github_repository.homelab-repo.name
#   environment     = github_repository_environment.production.environment
#   secret_name     = "TS_OAUTH_CLIENT_ID"
#   plaintext_value = var.tailscale-client-id
# }
# resource "github_actions_environment_secret" "gh-ts-oauth-secret" {
#   repository      = github_repository.homelab-repo.name
#   environment     = github_repository_environment.production.environment
#   secret_name     = "TS_OAUTH_SECRET"
#   plaintext_value = var.tailscale-client-secret
# }

resource "tailscale_tailnet_key" "tailscale-grx01-key" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  description   = "Tailscale grx01"
  tags          = ["tag:ci"]
}

resource "ssh_resource" "grx01" {
  host        = var.node-address
  user        = var.node-username
  private_key = file(var.private-ssh-key-path)
  triggers = {
    always_run = timestamp()
  }
  commands = flatten([
    # Install basic stuff
    "sudo dnf install --assumeyes curl git iproute bind-utils telnet epel-release",
    # Seteamos SELinux a permisivo (equivalente a desactivarlo)
    "sudo sed -Ei 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config",
    "sudo setenforce 0",
    # Enable Alma linux web console on port 9090
    "sudo systemctl enable --now cockpit.socket",
    # Se recomienda deshabilitar el firewall para el uso de k3s
    "sudo systemctl disable firewalld --now",
    # Configuramos los discos a montar
    [for disk in var.disk-mounts : "sudo mkdir -p ${disk.path} && sudo grep -q '${disk.uuid}' /etc/fstab && echo 'El disco ya existe, omitiendo' || echo 'UUID=${disk.uuid} ${disk.path} ${disk.type} ${disk.options}' | sudo tee -a /etc/fstab"],
    "sudo systemctl daemon-reload",
    "sudo mount -a",
    # Instalamos K3s
    "curl -sfL https://get.k3s.io | sudo sh -",
    # Copiamos el fichero de config para kubectl para despues descargarlo
    "mkdir -p /home/${var.node-username}/.kube && sudo cp /etc/rancher/k3s/k3s.yaml /home/${var.node-username}/.kube/config && chown ${var.node-username}:${var.node-username} /home/${var.node-username}/.kube/config",
    # Copiamos el archivo de configuracion del server de k3s
    "cat <<EOF | sudo tee /etc/rancher/k3s/config.yaml\n${templatefile("./k3s-config.tftpl", { "k8s-default-storage-path" = var.k8s-default-storage-path })}\nEOF",
    # Reiniciamos k3s para aplicar los cambios
    "sudo systemctl restart k3s",
    # Configuramos el IP Forward
    "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf",
    "echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf",
    "sudo sysctl -p /etc/sysctl.d/99-tailscale.conf",
    # Instalamos tailscale
    "curl -fsSL https://tailscale.com/install.sh | sh",
    "sudo tailscale up --ssh --advertise-tags=tag:ci --advertise-exit-node --accept-routes --advertise-routes=192.168.1.0/24 --auth-key=${tailscale_tailnet_key.tailscale-grx01-key.key}"
  ])

  # Descargamos el fichero de configuracion de kubectl y cambiamos la IP del loopback a la real
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.private-ssh-key-path} ${self.user}@${self.host}:~/.kube/config ./kubeconfig && sed -Ei 's/127.0.0.1/${var.node-address}/' ./kubeconfig"
  }

  depends_on = [tailscale_tailnet_key.tailscale-grx01-key]
}

# resource "github_actions_environment_secret" "gh-ts-host-ip" {
#   repository      = github_repository.homelab-repo.name
#   environment     = github_repository_environment.production.environment
#   secret_name     = "TS_HOST_IP"
#   plaintext_value = "grx01.taild52040.ts.net"
# }


# -------------------------------------------------------------------------------------------
# Releases de HELM y otros manifiestos de k8s
# -------------------------------------------------------------------------------------------
# Las releases de helm y manifiestos necesarios para el basico funcionamiento de la infra
# las gestioneremos con terraform, mientras que las releases de "aplicaciones"
# que despleguemos, es decir, las que proveen funcionalidad no relacionada con la infra,
# seran gestionadas por Argo CD
# -------------------------------------------------------------------------------------------

# Instalamos cert manager para la gestion de certificados, principalmente del SSL de los ingress
resource "helm_release" "cert-manager" {
  name              = "cert-manager"
  version           = "v1.16.1"
  repository        = "https://charts.jetstack.io"
  chart             = "cert-manager"
  create_namespace  = true
  namespace         = "cert-manager"
  dependency_update = true
  force_update      = true
  verify            = false
  wait              = true
  wait_for_jobs     = true
  timeout           = 600
  depends_on        = [ssh_resource.grx01]

  set {
    name  = "crds.enabled"
    value = true
  }
}

# Aplicamos el secreto que contiene el token de cloudflare
# para generar los certificados.
# Nota: Los proveedores de kubernetes y kubectl no son aptos para este
# caso. En el caso de kubernetes_manifest filtra los secretos y kubectl
# produce errores varios. Ver: https://medium.com/@danieljimgarcia/dont-use-the-terraform-kubernetes-manifest-resource-6c7ff4fe629a
resource "helm_release" "k8s-cloudflare-secret" {
  name       = "cloudflare-secret"
  repository = "https://bedag.github.io/helm-charts/"
  chart      = "raw"
  version    = "2.0.0"
  values = sensitive([
    <<-EOF
      resources:
        - apiVersion: v1
          kind: Secret
          metadata:
            name: cloudflare-api-token-secret
            namespace: cert-manager
          type: Opaque
          stringData:
            api-token: ${sensitive(var.cloudflare-token)}
      EOF
  ])
}

# Aplicamos el ClusterIssuer encargado de generar los certificados
# con un challenge DNS desde cloudflare
resource "kubernetes_manifest" "cloudflare-issuer" {
  manifest = yamldecode(file("./kubernetes/cloudflare-certs.yaml"))
}

# Instalamos el stack de observabilidad de prometheus+grafana
resource "helm_release" "kube-prometheus-stack" {
  name              = "kube-prometheus-stack"
  version           = "65.2.0"
  repository        = "https://prometheus-community.github.io/helm-charts"
  chart             = "kube-prometheus-stack"
  create_namespace  = true
  namespace         = "observability"
  dependency_update = true
  force_update      = true
  verify            = false
  wait              = true
  wait_for_jobs     = true
  depends_on        = [ssh_resource.grx01]

  values = sensitive([
    file("kubernetes/prom.values.yaml")
  ])

  set_sensitive {
    name  = "grafana.adminPassword"
    value = sensitive(var.grafana-admin-password)
  }
}

# Instalamos trivy operator para monitorizar la seguridad del cluster
resource "helm_release" "trivy-operator" {
  name              = "trivy-operator"
  version           = "0.24.1"
  repository        = "https://aquasecurity.github.io/helm-charts/"
  chart             = "trivy-operator"
  create_namespace  = true
  namespace         = "trivy-operator"
  dependency_update = true
  force_update      = true
  verify            = false
  wait              = true
  wait_for_jobs     = true
  timeout           = 600
  depends_on        = [ssh_resource.grx01]

  # Habilitamos la integracion con prometheus
  set {
    name  = "serviceMonitor.enabled"
    value = true
  }
}

# Instalamos pihole para gestion de DNS, bloqueo de trackers y adblocking
resource "helm_release" "k8s-pihole-secret" {
  name       = "k8s-pihole-secret"
  repository = "https://bedag.github.io/helm-charts/"
  chart      = "raw"
  version    = "2.0.0"
  values = sensitive([
    <<-EOF
      resources:
        - apiVersion: v1
          kind: Namespace
          metadata:
            name: pihole
        - apiVersion: v1
          kind: Secret
          metadata:
            name: pihole-secrets
            namespace: pihole
          type: Opaque
          data:
            WEBPASSWORD: ${base64encode(var.pihole-admin-password)}
      EOF
  ])
}
resource "kubernetes_manifest" "pihole-storage" {
  manifest = yamldecode(file("./kubernetes/pihole/storage-pihole.yaml"))
}
resource "kubernetes_manifest" "pihole-storage-dnsmasq" {
  manifest = yamldecode(file("./kubernetes/pihole/storage-dnsmasq.yaml"))
}
resource "kubernetes_manifest" "pihole" {
  manifest   = yamldecode(file("./kubernetes/pihole/pihole.yaml"))
  depends_on = [kubernetes_config_map.pihole-dominios-internos]
}

resource "helm_release" "argocd" {
  name              = "argocd"
  repository        = "https://argoproj.github.io/argo-helm"
  chart             = "argo-cd"
  version           = "7.6.12"
  create_namespace  = true
  namespace         = "argocd"
  dependency_update = true
  force_update      = true
  verify            = false
  wait              = true
  wait_for_jobs     = true
  timeout           = 600
  depends_on        = [ssh_resource.grx01]

  values = sensitive([
    file("kubernetes/argo.values.yaml")
  ])

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = sensitive(bcrypt(var.argo-admin-password))
  }
}

resource "kubernetes_manifest" "argocd-apps" {
  manifest   = yamldecode(file("./kubernetes/argocd/argocd.yaml"))
  depends_on = [helm_release.argocd]
}

resource "helm_release" "vaultwarden-admin-secret" {
  name       = "vaultwarden-admin-secret"
  repository = "https://bedag.github.io/helm-charts/"
  chart      = "raw"
  version    = "2.0.0"
  values = sensitive([
    <<-EOF
      resources:
        - apiVersion: v1
          kind: Secret
          metadata:
            name: vaultwarden-admin-secret
            namespace: misc
          type: Opaque
          data:
            ADMIN_TOKEN: ${sensitive(base64encode(var.vaultwarden-admin-secret))}
      EOF
  ])
}