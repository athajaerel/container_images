#!/bin/bash

KEYS=$(find certs -name *key -type f)
CERTS=$(find certs -name *crt -type f)

echo ">>> Check: Private keys valid"

for K in ${KEYS}; do
	EXTRA=""
	if [ "x${K}x" == "xcerts/ca.keyx" ] ; then
		EXTRA="-passin=file:certs/ca-password.txt"
	fi
	echo ${K}:
	openssl pkey -check -in ${K} -noout ${EXTRA}
done

echo ">>> Check: Certs match keys"
for C in ${CERTS}; do
	K=${C%.crt}.key
	EXTRA=""
	if [ "x${K}x" == "xcerts/ca.keyx" ] ; then
		EXTRA="-passin=file:certs/ca-password.txt"
	fi
	if [ -e ${K} ] ; then
		KH=$(openssl rsa -noout -modulus -in ${K} ${EXTRA})
		CH=$(openssl x509 -noout -modulus -in ${C})
		if [ "x${KH}x" == "x${CH}x" ] ; then
			echo ${C} matches ${K}
		else
			echo ${C} does not match ${K}
			exit 1
		fi
	fi
done

echo ">>> Check: CA cert has CA:TRUE"
openssl x509 -text -noout -in certs/ca.crt | grep -q CA:TRUE
CA_CHECK=$?
if [ $CA_CHECK -eq 0 ] ; then
	echo CA:TRUE found
else
	echo CA:TRUE not found!
	exit 1
fi

echo ">>> Check: CA cert is self-signed \(AKID matches SKID\)"
CA_AKID=$(botan cert_info certs/ca.crt | awk '/^Authority keyid:/ {print $3}')
CA_SKID=$(botan cert_info certs/ca.crt | awk '/^Subject keyid:/ {print $3}')
if [ "x${CA_AKID}x" == "x${CA_SKID}x" ] ; then
	echo Correct: AKID matches SKID
else
	echo Bad CA: AKID does not match SKID
	exit 1
fi

echo ">>> Check: CA chain"
for C in ${CERTS}; do
	case ${C} in (*"-combined"*)
		continue
		;;
	esac
	if [ "x${C}x" == "xcerts/ca.crtx" ] ; then
		continue
	fi
	AKID=$(botan cert_info ${C} | awk '/^Authority keyid:/ {print $3}')
	if [ "x${AKID}x" == "x${CA_SKID}x" ] ; then
		echo certs/ca.crt signed ${C}
	else
		echo "certs/ca.crt didn't sign ${C}"
		exit 1
	fi
	openssl verify -verbose -CAfile certs/ca.crt ${C}
done
