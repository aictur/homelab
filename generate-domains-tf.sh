#!/bin/bash

# Comprobamos que tenemos jq instalado
if ! which jq > /dev/null 2> /dev/null; then
  echo "jq no instalado, por favor instalalo y vuelve a intenterlo."
  exit 1
fi

# Regeneramos el fichero de terraform vacio si existe
if [ -f domains.tf ]; then
  rm domains.tf
fi
touch domains.tf

# Iteramos sobre los dominios
DOMAIN_COUNT=$(jq length domains.json)
for INDEX_DOMAIN in $(seq 0 $(($DOMAIN_COUNT - 1))); do
  TUNNEL=$(jq -r ".[$INDEX_DOMAIN].tunnel" domains.json)
  VALUE=$(jq -r ".[$INDEX_DOMAIN].value" domains.json)
  SERVICE=$(jq -r ".[$INDEX_DOMAIN].service" domains.json)

  SUBDOMAIN=$(echo $VALUE | sed 's/\.aictur\.dev$//' | sed 's/\./-/g')

  # Si es necesario creamos el tunel de cloudflare
  if [ "$TUNNEL" = true ]; then
    echo """resource \"cloudflare_dns_record\" \"domain-$SUBDOMAIN\" {
  zone_id = var.cloudflare-zone-id
  name = \"$SUBDOMAIN\"
  content = \"\${cloudflare_zero_trust_tunnel_cloudflared.cloudflare-tunnel.id}.cfargotunnel.com\"
  type = \"CNAME\"
  proxied = true
  ttl = 1
  depends_on = [ cloudflare_zero_trust_tunnel_cloudflared.cloudflare-tunnel ]
}""" >> domains.tf
  fi
done