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
6. Obtener un token de cloudflare con permisos de edicion de tunel (Cloudflare Tunnel) y acceso a aplicaciones a nivel de cuenta (Access: Apps and Policies) y edicion de DNS a nivel de zona.
7. Obtener un OAuth client y secret para Tailscale, asi como la Tailnet

### TODOs

- Jenkins
  - Reiniciar argo
  - Reiniciar pihole
- Servidor de [notificaciones](https://ntfy.sh/)
- Backend provider OVH (S3) o Azure Blob
- Servidor de mail para envio de notificaciones
- StorageClass para el ssd
- Cambiar `reclaimPolicy: Delete` por `Retain` en `storageclass/local-path`
- Backups
  - k3s
  - Volumenes: [gemini](https://github.com/FairwindsOps/gemini), [velero](https://github.com/vmware-tanzu/velero), [snapscheduler](https://github.com/backube/snapscheduler)
- Vaultwarden
- Autoescalado a 0 con KEDA
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
