# Source in default environment variables
. default_env.sh

# Source in all functions
. vault_demo_functions.sh 

VAULT_USE_TLS=true
VAULT_ADDR=https://${VAULT_HOST}:${VAULT_PORT}

. initial_root_token

PKI_PATH=pki_int_main
CERT_BASE=shortttl.demo.moto.com
revoke ${PKI_PATH} $(cat /var/tmp/${CERT_BASE}.serial)
