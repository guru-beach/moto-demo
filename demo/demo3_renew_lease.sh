# Source in default environment variables
. default_env.sh

# Source in all functions
. vault_demo_functions.sh 

VAULT_USE_TLS=true
VAULT_ADDR=https://${VAULT_HOST}:${VAULT_PORT}

. initial_root_token

CERT_BASE=shortttl.${DEMO_DOMAIN}
while true;do
    echo "$(date +%H:%M:%S): Renewing Certificate"
    issue_cert ${CERT_BASE} 60 pki_int_main short-ttl-${ROOT_ROLE}
    sleep 30
done

