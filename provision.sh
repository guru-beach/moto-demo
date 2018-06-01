. /demo/default_env.sh

IP=$(ip -f inet addr show eth1 | grep -Po 'inet \K[\d.]+')
echo ${IP} vault1.${DEMO_DOMAIN} >> /etc/hosts

mkdir -p /etc/vault
cat > /etc/vault/config.hcl <<EOF
storage "consul" {
  address = "${IP}:8500"
  path    = "vault"
}

listener "tcp" {
  address            = "0.0.0.0:8200"
  tls_cert_file      = "/etc/certs/${VAULT_HOST}_crt.pem"
  tls_key_file       = "/etc/certs/${VAULT_HOST}_key.pem"
  tls_client_ca_file = "/etc/certs/${VAULT_HOST}_ca_chain.pem"
}
EOF

mkdir -p /etc/bash/bashrc.d
echo "alias ll='ls -latr'" >> /etc/bash/bashrc.d/jake_preferences
echo "set -o vi" >> /etc/bash/bashrc.d/jake_preferences
