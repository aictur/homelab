# Infra propia

TODO: Descripcion

## Requisitos previos manuales

1. Instalar Alma Linux
2. Configurar networking (IP Fija y no usar search ni DNSs).

    - Evitar usar `search` ya que causa problemas con cert-manager.
    - Evitar configurar DNSs ya que k3s coge el `resolv.conf` del host y nos saltamos CoreDNS, dejandonos sin DNS interno en k8s.

3. Crear y permitir al usuario de terraform usar sudo sin password.
4. Importar SSH keys.
5. Anadir `/usr/local/bin` a la opcion `secure_path` de `/etc/sudoers` (Fix para usar `k3s` con `sudo`).

### TODOs

- Aplicar [wireguard](https://github.com/wg-easy/wg-easy/wiki/Using-WireGuard-Easy-with-Kubernetes) con terraform
- Backend provider Azure Blob
- Flujo de crear dominios
  - Crear tunel cloudflare si es publico
  - Crear registro DNS en pihole
- StorageClass para el ssd
- Cambiar `reclaimPolicy: Delete` por `Retain` en `storageclass/local-path`
- Backups
  - k3s
  - Volumenes
- DB Operator
- Nextcloud
- Jellyfin
- Argo CD
- Vaultwarden
- Dashboards de grafana declarativamente
  - Trivy Operator: 17813
- Alertas basicas
  - Espacio en SSD OS
  - Espacio en HDD Seagate
  - Consumo RAM
  - Consumo CPU
  - Ancho de banda
  - Trivy vulnerabilidad
- Certificados
  - MQTT
  - MySQL
- README
  - Stack utilizado: una lista de servicios (cloudflare, terraform, k8s...)
  - Infografico de la arquitectura
  - Protocolo de creacion de aplicacion
  - Protocolo de creacion de dominio
- Github Actions
  - Verificar commit firmado?
  - Gitleaks
  - Trivy
  - Kubescape
  - [Snyk](https://github.com/marketplace/actions/snyk)?
  - [Wireguard tunel](https://github.com/marketplace/actions/wireguard-session)
  - [Setup terraform](https://github.com/marketplace/actions/hashicorp-setup-terraform)
  - [Cache terraform](https://github.com/marketplace/actions/terraform-cache)
