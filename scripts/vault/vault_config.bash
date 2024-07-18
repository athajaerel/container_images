#!/bin/bash
set -euo pipefail

eval ${PASS_ARGS}

# Return JSON from GETting a path at the server
# $1: path
get_json() {
	curl -XGET -H 'Content-Type: application/json' \
		--no-progress-meter \
		https://127.0.0.1:8200/$1
}

# POST some JSON to a path at the server
# $1: path
# $2: body
post_json() {
	curl -XPOST -H 'Content-Type: application/json' -d "$2" \
		--no-progress-meter \
		https://127.0.0.1:8200/$1
}

# Idea: do apk add in the same file as apk del, so we get slimmer layers
# Just install stuff that's not temporary in "requirements".
TEMPPKGS="curl libcap jq ca-certificates"
apk add --no-cache ${TEMPPKGS}

# Seems buildah really doesn't like cap'd binaries.
# Makes sense --- the buildah would need them too.
# Maybe apply them at run time not build time?
#setcap cap_net_bind_service+ep /usr/bin/vault
#setcap cap_ipc_lock+ep /usr/bin/vault

chown ${UID}:${UID} -R /data
chown ${UID}:${UID} -R /logs
chown ${UID}:${UID} -R /etc

#cat /etc/tls/vault.crt /etc/tls/ca.crt >/etc/tls/vault-combined.crt
cp -p /etc/tls/ca.crt /usr/local/share/ca-certificates/
update-ca-certificates

vault server -config=/etc/vault.d/config.hcl &

sleep 2

# wait until socket is accepting connections
while ! timeout 5 bash -c "echo > /dev/tcp/127.0.0.1/8200"; do
	sleep 5
done

# ofc it's not inited...
#IS_INITED=$(get_json v1/sys/init | jq .initialized)
#echo Vault inited: ${IS_INITED}

#_cluster,_unseal,_check,_configure

BODY='{"secret_shares": 3, "secret_threshold": 2}'
RESULT=$(post_json v1/sys/init "${BODY}")
KEYS_B64=$(<<<${RESULT} jq .keys_base64)
ROOT_TOKEN=$(<<<${RESULT} jq .root_token)
echo Keys: ${KEYS_B64}
echo Root token: ${ROOT_TOKEN}

# Write unseal keys and root token

# Redirect logs to stdout/stderr if possible?

apk del --no-cache ${TEMPPKGS}
