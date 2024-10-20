variable "gh-token" {
  type = string
  description = "Token de github para la autogestion del repositorio de Github"
  sensitive = true
}
variable "gh-repo-name" {
  type = string
  description = "Nombre del repo de github"
  default = "homelab"
}

variable "node-address" {
  type = string
  description = "Direccion IP del nodo"
}
variable "node-username" {
  type = string
  description = "Usuario SSH del nodo"
}
variable "private-ssh-key-path" {
  type = string
  description = "Ruta a la clave privada para conectar por ssh al nodo"
}

variable "disk-mounts" {
  type = list(object({
    uuid = string
    path = string
    type = string
    options = string
  }))
  description = "Lista de objetos representando los discos a montar (fstab)"
}

variable "k8s-default-storage-path" {
  type = string
  description = "Ruta en la que se almacenaran los volumenes por defecto de k3s"
}

variable "cloudflare-token" {
  type = string
  sensitive = true
  description = "Token de cloudflare para la gestion de los dominios publicos"
}

variable "cloudflare-domain" {
  type = string
  description = "Dominio para DNSs y el tunel de cloudflare"
}

variable "cloudflare-zone-id" {
  type = string
  description = "Zona de cloudflare"
  sensitive = true
}

variable "cloudflare-account-id" {
  type = string
  description = "Account ID de cloudflare"
  sensitive = true
}

variable "cloudflare-tunnel-secret" {
  type = string
  description = "Secreto para el tunel de cloudflare"
}

variable "pihole-admin-password" {
  type = string
  sensitive = true
  description = "Password para el usuario admin de PiHole"
}
variable "grafana-admin-password" {
  type = string
  sensitive = true
  description = "Password para el usuario admin de grafana"
}