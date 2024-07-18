#!/bin/bash
set -euo pipefail

eval ${PASS_ARGS}

TEMPPKGS="wget gnupg perl-utils zip"
apk add --no-cache ${TEMPPKGS}

echo ">>> Getting Hashicorp's public key."

# Use an out-of-band key server, otherwise this is all pointless
KEYBASE_DOMAIN=keybase.io
KEYBASE_OUTPUT=keys/hashicorp.asc
KEYBASE_KEY=${KEYBASE_DOMAIN}/hashicorp/pgp_keys.asc
wget https://${KEYBASE_KEY} -O ${KEYBASE_OUTPUT}

echo ">>> Creating GPG environment."

export GNUPGHOME=./.gnupg
TEMP_EMAIL=mister.flibble@example.com
gpg --quick-generate-key --batch --passphrase "" ${TEMP_EMAIL}

echo ">>> Verifying public key."

gpg --import keys/hashicorp.asc
# sign by fingerprint
gpg --quick-sign-key ${HASHICORP_FINGERPRINT}
GPGOUT=$(gpg --fingerprint --list-signatures "HashiCorp Security")

echo "${GPGOUT}"

# check key ID
AWK_PROG='/^sig  / {print $2}'
FINGIES=$(<<<${GPGOUT} awk "${AWK_PROG}" | sort -u)

VERIFIED="false"
for F in ${FINGIES}; do
	[ "x${F}" == "x${HASHICORP_KEY_ID}" ] && VERIFIED="true"
done
if [ "x${VERIFIED}" == "xfalse" ]; then
	echo "Not verified."
	exit 1
fi

echo ">>> Downloading Vault."

mkdir -p zips
VAULT_DOMAIN=releases.hashicorp.com
VAULT_ARCH=amd64
VAULT_OS=linux
VAULT_ZIPFILE=vault_${VAULT_VERSION}_${VAULT_OS}_${VAULT_ARCH}.zip
VAULT_OUTPUT=zips/vault_${VAULT_VERSION}_${VAULT_OS}_${VAULT_ARCH}.zip
VAULT_LOCATION=${VAULT_DOMAIN}/vault/${VAULT_VERSION}
VAULT_FLAGS=--progress=bar:force:noscroll
#wget ${VAULT_FLAGS} https://${VAULT_LOCATION}/${VAULT_ZIPFILE} -O ${VAULT_OUTPUT}
cp cheat/vault_${VAULT_VERSION}_${VAULT_OS}_${VAULT_ARCH}.zip ${VAULT_OUTPUT}

echo ">>> Getting signatures."

VAULT_SIGS=zips/SHA256SUMS
VAULT_SIGFILE=vault_${VAULT_VERSION}_SHA256SUMS
wget https://${VAULT_LOCATION}/${VAULT_SIGFILE} -O ${VAULT_SIGS}
wget https://${VAULT_LOCATION}/${VAULT_SIGFILE}.sig -O ${VAULT_SIGS}.sig

echo ">>> Verifying download."

# Verify the signatures are good
GPGOUT=$(gpg --verify ${VAULT_SIGS}.sig ${VAULT_SIGS} 2>&1)
<<<${GPGOUT} grep -q "Good signature"
if [ $? -ne 0 ]; then
	echo "Verification failed."
	exit 1
fi

echo ">>> Verifying Vault package."

# Verify the Vault zipfile
cd $(dirname ${VAULT_SIGS})
SHASUM_FLAGS="--algorithm 256 --ignore-missing --check"
shasum ${SHASUM_FLAGS} $(basename ${VAULT_SIGS})
cd -

echo ">>> Installing Vault package."

unzip -d /usr/bin/ ${VAULT_OUTPUT} vault
unzip -d /usr/share/doc/vault/ ${VAULT_OUTPUT} LICENSE.txt

chmod 0755 /usr/bin/vault

echo ">>> All good. Install done."

rm -rf ${GNUPGHOME}
unset GNUPGHOME
apk del --no-cache ${TEMPPKGS}
