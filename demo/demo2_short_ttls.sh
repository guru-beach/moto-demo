# Source in default environment variables
. default_env.sh

# Source in all functions
. vault_demo_functions.sh 

VAULT_USE_TLS=true
VAULT_ADDR=https://${VAULT_HOST}:${VAULT_PORT}

. initial_root_token
ROLE=short-ttl-moto-com

# Only try to create the role if it doesn't exist
vault read pki_int_main/roles/${ROLE} &> /dev/null
if [ $? -gt 0 ];then
  create_role ${ROLE} pki_int_main demo.moto.com ${INTERMEDIATE_CERT_TTL}
fi

CERT_BASE=shortttl.demo.moto.com
issue_cert shortttl.demo.moto.com 60 pki_int_main short-ttl-moto-com

while true;do
  verify ${CERT_BASE}
  sleep 5
done
