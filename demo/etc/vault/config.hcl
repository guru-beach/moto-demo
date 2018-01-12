storage "consul" {
  address = "172.17.8.101:8500"
  path    = "vault"
}

listener "tcp" {
  address            = "0.0.0.0:8200"
  tls_cert_file      = "/etc/certs/vault1.dev.moto.com_crt.pem"
  tls_key_file       = "/etc/certs/vault1.dev.moto.com_key.pem"
  tls_client_ca_file = "/etc/certs/vault1.dev.moto.com_ca_chain.pem"
}
