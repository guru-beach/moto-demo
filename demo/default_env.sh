ROOT_PKI_PATH=${ROOT_PKI_PATH:-pki_root}
ROOT_DOMAIN=${ROOT_DOMAIN:-hashidemos.com}
DEMO_DOMAIN=dev.${ROOT_DOMAIN}

VAULT_DOCKER=vault
VAULT_VERSION=${VAULT_VERSION:-0.10.1}
VAULT_IMAGE=${VAULT_DOCKER}:${VAULT_VERSION}
VAULT_HOST=vault1.${DEMO_DOMAIN}
VAULT_PORT=${VAULT_PORT:-8200}

CONSUL_DOCKER=consul
CONSUL_VERSION=${CONSUL_VERSION:-1.0.6}
CONSUL_IMAGE=${CONSUL_DOCKER}:${CONSUL_VERSION}
CONSUL_HOST=consul1.${DEMO_DOMAIN}

CONSUL_TEMPLATE_VERSION=0.19.4
# Fixing the arch because this is probably always going to run on a fixed platform in a Vagrant
CONSUL_TEMPLATE_BIN="consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.tgz"
CONSUL_TEMPLATE_URL="https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/${CONSUL_TEMPLATE_BIN}"

# Root CA Certs can most likely be long-lived certs.  Set for 10 years
ROOT_CERT_TTL=${ROOT_CERT_TTL:-87648h}
ROOT_ROLE=${ROOT_DOMAIN/./-}

# Default PKI Intermediate Path
INTERMEDIATE_CA_PATH=${INTERMEDIATE_CA_PATH:-pki_int_main}
# Intermediate certs can also be longer lived. Set for 5 years.
INTERMEDIATE_CERT_TTL=${INTERMEDIATE_CERT_TTL:-43824h}  

DEFAULT_TOKEN_TTL=120s

LOCAL_MOUNT=/var/tmp
DOCKER_MOUNT=/var/tmp/docker

# Local file used to store parameters. Typically used for curl commands payload
# DO NOT STORE LONG TERM DATA HERE!
# This file will get overwritten by any process needing to store input parameters.
INPUT_PARAMS=input-params.json
# Local fs version
LOCAL_INPUT_PARAMS=${LOCAL_MOUNT}/${INPUT_PARAMS}
# Docker fs version (if needed to be read in by the local process)
DOCKER_INPUT_PARAMS=${DOCKER_MOUNT}/${INPUT_PARAMS}
