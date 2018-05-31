. /demo/default_env.sh


# hosts entry for local name resolution
IP=$(ip -f inet addr show eth1 | grep -Po 'inet \K[\d.]+')
echo ${IP} ${VAULT_HOST} >> /etc/hosts

# Create vault directory and configuration file
mkdir -p /etc/vault
cat > /etc/vault/config.hcl <<EOL
storage "consul" {
  address = "172.17.8.101:8500"
  path    = "vault"
}

listener "tcp" {
  address            = "0.0.0.0:8200"
  tls_cert_file      = "/etc/certs/${VAULT_HOST}_crt.pem"
  tls_key_file       = "/etc/certs/${VAULT_HOST}_key.pem"
  tls_client_ca_file = "/etc/certs/${VAULT_HOST}_ca_chain.pem"
}
EOL
