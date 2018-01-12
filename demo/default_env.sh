VAULT_DOCKER=vault
VAULT_PORT=8200
ROOT_DOMAIN=moto.com
VAULT_HOST=vault1.dev.moto.com
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
# Docke fs version (if needed to be read in my the local process)
DOCKER_INPUT_PARAMS=${DOCKER_MOUNT}/${INPUT_PARAMS}
