# Read in the default environment variables
. default_env.sh

# Read in all shared functions
. vault_demo_functions.sh



# We don't want to use TLS at this point so make this nothing
VAULT_USE_TLS=
# Pull early so time it takes to pull down doesn't affect runs from service start
/usr/bin/docker pull vault:0.9.1

# Since we're running with two different names, deconflict the variable
# Run a dev version of the vault server to bootstrap the certs
echo "Starting Vault Dev Server"
systemctl start docker-vault-dev
sleep 10

VAULT_DOCKER_PREV=${VAULT_DOCKER}
VAULT_DOCKER=dev-vault
# Derive values from Docker Vault server
# During bootstraping, node names aren't necessary so we'll use the IP as well as the 
# Root token shown in the logs during start of dev server
VAULT_IP=$(docker inspect ${VAULT_DOCKER} | jq .[0].NetworkSettings.Networks.bridge.IPAddress | tr -d '"')
VAULT_ADDR=http://${VAULT_IP}:${VAULT_PORT}
VAULT_TOKEN=$(docker logs ${VAULT_DOCKER} 2>&1 | grep -E "Root Token:" | awk '{print $3}')

# Since consul will actually be writing locally, add its user to the local system so we don't have permissions issues.
groupadd -g 1000 consul
useradd -u 100 -g 1000 consul

mkdir -p /etc/certs
mkdir -p /var/consul/data && chown -R consul:consul /var/consul/data
mkdir -p /etc/consul && chown -R consul:consul /etc/consul
# Vault will only be reading mounted data, so no need for mapping user
# Annoyingly, both consul and vault users have the same UID/GID in the container
# This could easily be fixed by just cutting a new docker with new UID/GID mappings
mkdir -p /etc/vault

bootstrap_ca

# Create the roles that will create the certs
create_role moto-com pki_int_main moto.com ${INTERMEDIATE_CERT_TTL}
create_role consul-dev-moto-com pki_int_main dev.moto.com ${INTERMEDIATE_CERT_TTL}
create_role vault-dev-moto-com pki_int_main dev.moto.com ${INTERMEDIATE_CERT_TTL}

# Issue certs
issue_cert moto.com 168h pki_int_main moto-com
issue_cert consul1.dev.moto.com 168h pki_int_main consul-dev-moto-com
issue_cert vault1.dev.moto.com 168h pki_int_main vault-dev-moto-com

# Copy the local mount files over to the certs directory.  This also gets mounted
# Into the Consul and Vault docker containers for usage
cp ${LOCAL_MOUNT}/*.pem /etc/certs
cat /etc/certs/vault1.dev.moto.com_ca_chain.pem /etc/certs/CA_cert.pem > /etc/certs/vault1.dev.moto.com_ca_chain_full.pem

# stop the dev server if we're done with it
echo "Stopping Vault Dev Server"
systemctl stop docker-vault-dev

# Go back to using the default name
VAULT_DOCKER=${VAULT_DOCKER_PREV}
# Now that the certs are in place, restart the services that probably failed on boot
echo "Starting main production Vault and Consul"
systemctl start docker-consul docker-vault
sleep 10

VAULT_USE_TLS=true
VAULT_ADDR=https://${VAULT_HOST}:${VAULT_PORT}
OUTPUT_FILE=/demo/vault_init_output.txt
INITIAL_ROOT_TOKEN=/demo/initial_root_token

# Initialize vault and capture output.
echo "Initializing Vault"
vault init | grep : > ${OUTPUT_FILE}

# Yeah, I made fun of this in the slides, but that's different!
chmod 0600 ${OUTPUT_FILE}

# Unseal the vault with the unseal keys
for i in $(cat ${OUTPUT_FILE} | grep Unseal | cut -f 2 -d : | tr -d ' ');do
  vault unseal $i
done

# Capture the root token from the output
echo "VAULT_TOKEN=$(cat ${OUTPUT_FILE} | grep "Initial Root Token" | cut -f 2 -d : | tr -d ' ')" > ${INITIAL_ROOT_TOKEN}
echo "Saved Initial Root Token to ${INITIAL_ROOT_TOKEN}"
. ${INITIAL_ROOT_TOKEN}

# Why bootstrap twice?  Well, because the dev server is dead and didn't persist anything
echo "Bootstrapping CA"
bootstrap_ca
