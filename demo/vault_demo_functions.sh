# Import the demo magic to allow for more controlled demos
. demo-magic.sh -d -p

vault () {
  # Wrapper to run vault command line from docker instance.   Use local mount
  # for storing arbitrary data loaded on the local system
  if [ -n "${VAULT_USE_TLS}" ];then
    AUTH_ENV="-e VAULT_CACERT=/etc/certs/${VAULT_HOST}_ca_chain_full.pem \
              -e VAULT_CLIENT_CERT=/etc/certs/${VAULT_HOST}_crt.pem \
              -e VAULT_CLIENT_KEY=/etc/certs/${VAULT_HOST}_key.pem \
              -e VAULT_ADDR=https://${VAULT_HOST}:${VAULT_PORT} \
              -e VAULT_TOKEN=${VAULT_TOKEN} \
              -v /etc/certs:/etc/certs"
  else
    AUTH_ENV="-e VAULT_TOKEN=${VAULT_TOKEN} \
              -e VAULT_ADDR=http://${VAULT_HOST}:${VAULT_PORT}"

  fi
  VAULT_IP=$(docker inspect ${VAULT_DOCKER} | jq .[0].NetworkSettings.Networks.bridge.IPAddress | tr -d '"')

  docker run  \
    --cap-add=IPC_LOCK --rm \
    ${AUTH_ENV} \
    -v ${LOCAL_MOUNT}:${DOCKER_MOUNT} \
    --add-host ${VAULT_HOST}:${VAULT_IP} \
    vault $@
}

vault_dev_server () {
    # Run an in memory vault server.   This should only be used for bootstrapping, but could be used for other testing as well.
    docker rm dev-vault
    docker run  \
    --cap-add=IPC_LOCK --rm \
    -v ${LOCAL_MOUNT}:${DOCKER_MOUNT} \
    --name dev-vault \
    --add-host ${VAULT_HOST}:172.18.0.2 \
    vault 
}

revoke () {
  # Revoke a certificate and place an entry in the CRL hosted in Vault
  PKI_PATH=$1
  SERIAL=$2
   
  CURL_CERTS=''
  if [ -n "${VAULT_USE_TLS}" ];then
    CURL_CERTS="--cacert /etc/certs/${VAULT_HOST}_ca_chain_full.pem  --cert /etc/certs/${VAULT_HOST}_crt.pem --key /etc/certs/${VAULT_HOST}_key.pem"
    VAULT_ADDR=https://${VAULT_HOST}:${VAULT_PORT}
  fi

  echo "{
    \"serial_number\" : \"${SERIAL}\"
  }" > ${LOCAL_INPUT_PARAMS}


  echo $(green "Revoking from ${PKI_PATH} serial ${SERIAL}")
  curl -s \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    ${CURL_CERTS} \
    --request POST \
    --data @${LOCAL_INPUT_PARAMS} \
    ${VAULT_ADDR}/v1/${PKI_PATH}/revoke 

  echo $(green "Checking CRL")
  curl -s \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    ${CURL_CERTS} \
    --request GET \
    ${VAULT_ADDR}/v1/${PKI_PATH}/crl/pem | openssl crl -inform PEM -text -noout

}

bootstrap_ca () {
  
  # Bootstraps CA and initial client certificates for securing Vault with TLS

  CURL_CERTS=''
  if [ -n "${VAULT_USE_TLS}" ];then
    CURL_CERTS="--cacert /etc/certs/${VAULT_HOST}_ca_chain_full.pem  --cert /etc/certs/${VAULT_HOST}_crt.pem --key /etc/certs/${VAULT_HOST}_key.pem"
    VAULT_ADDR=https://${VAULT_HOST}:${VAULT_PORT}
  fi

  # Allow for certificate stores
  echo $(green "Mounting CA Certificate PKI Backend")
  pe "vault secrets enable pki"

  # Set max lease time for root pki setup
  echo $(green "Tuning CA Certificate PKI Backend")
  pe "vault secrets tune -max-lease-ttl=${ROOT_CERT_TTL} pki"

  #  ttl=${ROOT_CERT_TTL}

  # Use the HTTP API versus the command version due to quote removal when passing bash arguments with quotes in them.
  echo "{
    \"common_name\" : \"${ROOT_DOMAIN} CA 1\",
    \"ttl\"         : \"${ROOT_CERT_TTL}\"
  }" > ${LOCAL_INPUT_PARAMS}

  OUTPUT_FILE=${LOCAL_MOUNT}/root_ca_output.json
  echo $(green "Generating CA Root certificate.  JSON output found at ${OUTPUT_FILE}")
  pe "curl -s \
    --header \"X-Vault-Token: ${VAULT_TOKEN}\" \
    ${CURL_CERTS} \
    --request POST \
    --data @${LOCAL_INPUT_PARAMS} \
    ${VAULT_ADDR}/v1/pki/root/generate/internal > ${OUTPUT_FILE}"

  jq -r '.data.certificate' ${OUTPUT_FILE} > ${LOCAL_MOUNT}/CA_cert.pem
  jq -r '.data.serial_number' ${OUTPUT_FILE} > ${LOCAL_MOUNT}/CA_cert.serial

  # Cert CRL and CA information
  echo $(green "Updating CRL And CA information")
  pe "vault write pki/config/urls \
    issuing_certificates=${VAULT_ADDR}/v1/pki/ca \
    crl_distribution_points=${VAULT_ADDR}/v1/pki/crl"

  # Abstracting name for re-usability
  PKI_PATH=pki_int_main
  MAX_TTL=${INTERMEDIATE_CERT_TTL}

  # Setup intermediate CA endpoint
  echo $(green "Mounting PKI Backend ${PKI_PATH}")
  pe "vault secrets enable -path=${PKI_PATH} pki"

  # Set max lease time for pki
  echo $(green "Tuning PKI Backend ${PKI_PATH}")
  pe "vault secrets tune -max-lease-ttl=${MAX_TTL} ${PKI_PATH}"

  # Use the HTTP API versus the command version due to quote removal when passing bash arguments with quotes in them into functions like the docker run
  echo "{
    \"common_name\" : \"${ROOT_DOMAIN} Intermediate 1\",
    \"ttl\"         : \"${MAX_TTL}\"
  }" > ${LOCAL_INPUT_PARAMS}

  OUTPUT_FILE=${LOCAL_MOUNT}/intermediate_csr_output.json
  echo $(green "Generating Intermediate CSR.  JSON output found at ${OUTPUT_FILE}")
  echo $(green "CSR located at ${LOCAL_MOUNT}/${PKI_PATH}.csr")
  pe "curl -s \
    --header \"X-Vault-Token: ${VAULT_TOKEN}\" \
    ${CURL_CERTS} \
    --request POST \
    --data @${LOCAL_INPUT_PARAMS} \
    ${VAULT_ADDR}/v1/${PKI_PATH}/intermediate/generate/internal \
    > ${OUTPUT_FILE}"

  jq -r '.data.csr' ${OUTPUT_FILE} > ${LOCAL_MOUNT}/${PKI_PATH}.csr

  # Sign the intermediate cert with the root cert and save the cert file locally.
  OUTPUT_FILE=${LOCAL_MOUNT}/intermediate_csr_output.json
  echo $(green "Generating Intermediate PEM cert.  JSON output found at ${OUTPUT_FILE}")
  echo $(green "Certificate located at ${LOCAL_MOUNT}/${PKI_PATH}.pem")
  pe "vault write -format=json pki/root/sign-intermediate \
    csr=@${DOCKER_MOUNT}/${PKI_PATH}.csr \
    format=pem_bundle \
    > ${OUTPUT_FILE}"

  pe "jq -r '.data.certificate' ${OUTPUT_FILE} > ${LOCAL_MOUNT}/${PKI_PATH}.pem"

  # Set the intermediate certificate authorities signing certificate to the root-signed certificate.
  pe "vault write ${PKI_PATH}/intermediate/set-signed certificate=@${DOCKER_MOUNT}/${PKI_PATH}.pem"

  # Cert URL metadata
  echo $(green "Updating CRL And CA information for ${PKI_PATH}")
  pe "vault write ${PKI_PATH}/config/urls \
    issuing_certificates=${VAULT_ADDR}/v1/${PKI_PATH}/ca \
    crl_distribution_points=${VAULT_ADDR}/v1/${PKI_PATH}/crl"
}

create_role () {
  # Roles have permissions to create certificates for certain domains
  # This process creates leases which are probably not necessary for short-lived TTLs
  PRE_ROLE=${1:-$PKI_ROLE}
  ROLE=${PRE_ROLE//./-}
  LOCAL_PATH=${2:-$PKI_PATH}
  DOMAINS=${3:-$PKI_DOMAIN}
  MAX_TTL=${4:-$PKI_MAX_TTL}

  echo $(green "Creating role ${ROLE} in ${LOCAL_PATH}")
  pe "vault write ${LOCAL_PATH}/roles/${ROLE} \
      allowed_domains=${DOMAINS} \
      allow_subdomains=true \
      max_ttl=${MAX_TTL} \
      allow_any_name=true \
      generate_lease=true \
      enforce_hostnames=false"
}

issue_cert () {
  DOMAIN=${1:-$PKI_DOMAIN}
  TTL=${2:-$PKI_MAX_TTL}
  LOCAL_PATH=${3:-$PKI_PATH}
  PRE_ROLE=${4:-$PKI_ROLE}
  ROLE=${PRE_ROLE//./-}

  # Issue the certificates
  OUTPUT_FILE=${LOCAL_MOUNT}/${DOMAIN}_cert.json
  echo $(green "Creating cert for ${DOMAIN}.  JSON Output: ${OUTPUT_FILE}")
  pe "vault write -format=json ${LOCAL_PATH}/issue/${ROLE} \
      common_name=${DOMAIN} \
      ttl=${TTL} > ${OUTPUT_FILE}"

 
  # These are being written out to the filesystem, but could easily just be consumed 
  # in memory by any API
  echo $(green "Writing CA Chain ${LOCAL_MOUNT}/${DOMAIN}_ca_chain.pem")
  jq -r .data.ca_chain[0] ${OUTPUT_FILE} > ${LOCAL_MOUNT}/${DOMAIN}_ca_chain.pem
  echo $(green "Writing Full CA Chain ${LOCAL_MOUNT}/${DOMAIN}_ca_chain_full.pem")
  cat ${LOCAL_MOUNT}/${DOMAIN}_ca_chain.pem ${LOCAL_MOUNT}/CA_cert.pem > ${LOCAL_MOUNT}/${DOMAIN}_ca_chain_full.pem
  echo $(green "Writing cert ${LOCAL_MOUNT}/${DOMAIN}_crt.pem")
  jq -r .data.certificate ${OUTPUT_FILE} > ${LOCAL_MOUNT}/${DOMAIN}_crt.pem
  echo $(green "Writing private key ${LOCAL_MOUNT}/${DOMAIN}_key.pem")
  jq -r .data.private_key ${OUTPUT_FILE} > ${LOCAL_MOUNT}/${DOMAIN}_key.pem
  echo $(green "Writing serial ${LOCAL_MOUNT}/${DOMAIN}.serial")
  jq -r .data.serial_number ${OUTPUT_FILE} > ${LOCAL_MOUNT}/${DOMAIN}.serial

}

verify () {
  # Check the validity of a cert
  CA_FILE=${LOCAL_MOUNT}/$1_ca_chain_full.pem
  CERT=${LOCAL_MOUNT}/$1_crt.pem
  openssl verify -CAfile ${CA_FILE} ${CERT}
}
