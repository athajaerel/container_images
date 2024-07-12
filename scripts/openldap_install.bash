#!/bin/bash
set -exuo pipefail

eval ${PASS_ARGS}

# Zytrax's LDAP Guide: https://www.zytrax.com/books/ldap "... never
# has so much been written so incomprehensibly about a single
# topic..." :)

CAK='/etc/tls/ca.key'
CAP='/etc/tls/ca-password.txt'
CAC='/etc/tls/ca.crt'
SK='/etc/tls/ldaps.key'
SP='/etc/tls/ldaps-password.txt'
SC='/etc/tls/ldaps.crt'
SR='/etc/tls/ldaps.csr'

FLAGS_RNG="--format=base64 100"
FLAGS_GENSS="${CAK} '${cname}' --ca --days=3650 --path-limit=2 \
	--country=${country} --organization='${org}'"
FLAGS_KEYGEN="--algo=ECDSA --params=secp384r1"
FLAGS_GENPK="${SK} '${scn}' --dns='${alt_names}' \
	--email='${email}' --country=${country}  \
	--organization='${org}'"

#[ ! -e ${CAK} ] && (
#	botan2 rng ${FLAGS_RNG} >${CAP}
#	FLAG_PASS="--passphrase='$(more ${CAP})'"
#	botan2 keygen ${FLAGS_KEYGEN} ${FLAG_PASS} >${CAK}
#	FLAG_PASS="--key-pass='$(more ${CAP})'"
#	echo b gen_self_signed ${FLAGS_GENSS} ${FLAG_PASS}
#	botan2 gen_self_signed ${FLAGS_GENSS} ${FLAG_PASS} >${CAC}
#	D_CAK=$(openssl pkey -pubout -in ${CAK} -passin=file:${CAP})
#	D_CAC=$(openssl x509 -pubkey -in ${CAC} -noout)
#	diff <(<<<${D_CAK} openssl md5) <(<<<${D_CAC} openssl md5)
#	[ $? -ne 0 ] && echo "Key and cert don't match!"
#	D_CAAK=$(botan2 cert_info ${CAC} | grep "Authority keyid")
#	D_CASK=$(botan2 cert_info ${CAC} | grep "Subject keyid")
#	diff <(<<<${D_CAAK} cut -d: -f2) <(<<<${D_CASK} cut -d: -f2)
#	[ $? -ne 0 ] && echo "Not a CA cert"
#	#install /etc/tls/ca*.crt 
#	CADIR='/usr/local/share/ca-certificates/'
#	install ${CAC} ${CADIR} -m0444
#	chmod 0400 ${CAK}
#	chmod 0400 ${CAP}
#	chmod 0444 ${CAC}
#	update-ca-certificates
#	rm -f ${SK}
#)

#FLAGS_SC="--ca-key-pass=$(more ${CAP}) --duration=365 ${CAC} \
#	${CAK} ${SR}"

#[ ! -e ${SK} ] && (
#	botan2 rng ${FLAGS_RNG} >${SP}
#	botan2 keygen ${FLAGS_KEYGEN} >${SK}
#	botan2 gen_pkcs10 ${SK} ${FLAGS_GENPK} >${SR}
#	botan2 sign_cert ${FLAGS_SC} >${SC}
#	D_SK=$(openssl pkey -pubout -in ${SK})
#	D_SC=$(openssl x509 -pubkey -in ${SC} -noout)
#	diff <(<<<${D_SK} openssl md5) <(<<<${D_SC} openssl md5)
#	[ $? -ne 0 ] && echo "Key and cert don't match!"
#	chmod 0400 ${SK}
#	chmod 0400 ${SP}
#	chmod 0444 ${SC}
#	rm ${SR}
#)
