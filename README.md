# Moto Corp Demo -- Dynamic PKI Certificates using Hashicorp Vault

Vagrantfile based on https://github.com/coreos/coreos-vagrant/

DO NOT RUN THIS DEMO IN PRODUCTION!!!   There are some hard coded values like the Consul encrypt hash which are open to the internet.  This should only be used for demonstration purposes and then killed.

This is a Demo to show how to use Hashicorp Vault for creating static and dynamic TLS certificates.   

Basic Setup:
* CoreOS Stable version
* Consul and Vagrant in Docker containers
* Vault clients using Root Token


This works best if you use a terminal multiplexer (tmux) or a terminal that allows for splitting windows (I use iTerm2) so you can show the results of how one demo affects the other in one screen.  

## Prerequisites 
Requires a current version of Vagrant installed on the client machine. Run with 2.0.1 successfully.

## Start
Requires sudo access to run docker updates.   

```
$ git clone git@github.com:guru-beach/moto-demo.git
$ cd moto-demo
$ vagrant up
$ vagrant ssh
core@core-01 ~ $ sudo su -
core-01 ~ # cd /demo
core-01 demo #
```

## Demo 1

This demo bootstraps the TLS certificates needed to secure both Vault and Consul.  Currently only Vault is using TLS for client communication, though the consul client certs are created.  Once bootstrapped, all client connects will use the TLS certs.

```
core-01 demo # ./demo1_bootstrap_environment.sh
```

## Demo 2

This demo shows what it looks like to use short-lived TTLs with Vault.   Validity is verified using openssl verify against a local file, but can easily be used to look at in memory certs direct via the API.   Local certs were used to more easily allow the subsequent demos to use the previous one without tracking certificate serials (though those are being dumped as well).

Leave this demo running!

```
core-01 demo # ./demo2_short_ttls.sh
```

## Demo 3

This demo shows how a dynamic cert with TTLs can stay valid by using the renew endpoint for vault.  This demo should be run in a separate window to Demo2 while Demo2 is still running.   It will show how the certificates being verified.   


You can kill this process after a few minutes of showing the renewals work and wait for 60s to demonstrate how missing renewals affects the Demo2 process.

```
core-01 demo # ./demo3_renew_lease.sh
```


## Demo 4

This demo shows how certificate revocation with Vault updates the CRL automatically.   However, it doesn't show actually show that the certificate is invalid.  This is on purpose to demonstrate that just invalidating a certificate without a process that checks the CRL can be a security issue if those certificates were actually compromised.   The CRL is shown to be updated while the certificate still appears valid.

This demo should be run in another window alongside the currently running Demo2/3 windows.

```
core-01 demo # ./demo4_revoke_cert.sh
```

## Cleanup

Though probably not a huge security risk, it's best to tear down this demo when done.

```
core-01 demo # exit
core@core-01 ~ $ exit
$ vagrant destroy
```

