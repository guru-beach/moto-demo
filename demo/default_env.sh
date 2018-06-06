ROOT_PKI_MOUNT=pki
ROOT_DOMAIN=hashidemos.com
DEMO_DOMAIN=dev.${ROOT_DOMAIN}

VAULT_DOCKER=vault
VAULT_VERSION=0.10.1
VAULT_IMAGE=${VAULT_DOCKER}:${VAULT_VERSION}
VAULT_HOST=vault1.${DEMO_DOMAIN}
VAULT_PORT=8200

CONSUL_DOCKER=consul
CONSUL_VERSION=1.0.6
CONSUL_IMAGE=${CONSUL_DOCKER}:${CONSUL_VERSION}
CONSUL_HOST=consul1.${DEMO_DOMAIN}


# Root CA Certs can most likely be long-lived certs.  Set for 10 years
ROOT_CERT_TTL=87648h
ROOT_ROLE=${ROOT_DOMAIN/./-}

# Intermediate certs can also be longer lived. Set for 5 years.
INTERMEDIATE_CERT_TTL=43824h

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
