rm -f /etc/certs/*
rm -f /var/tmp/*.{json,pem}
systemctl stop docker-vault
