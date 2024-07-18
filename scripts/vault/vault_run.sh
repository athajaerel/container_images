#!/bin/sh

echo ">>> Starting Vault"
/usr/bin/vault server -config=/etc/vault.d/config.hcl
