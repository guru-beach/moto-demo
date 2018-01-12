# Source in default environment variables
. default_env.sh

# Source in all functions
. vault_demo_functions.sh 

VAULT_USE_TLS=true
VAULT_ADDR=https://${VAULT_HOST}:${VAULT_PORT}

. initial_root_token

CERT_BASE=shortttl.demo.moto.com
while true;do
    issue_cert shortttl.demo.moto.com 60 pki_int_main short-ttl-moto-com
    sleep 30
done

