#!/bin/bash
set -ex

LDAPUSER=_ldap
LDAPGROUP=_ldap
DEBUG_LEVEL=0

install -d /run/openldap -o ${LDAPUSER} -g ${LDAPUSER} -m 0755

exec 2>&1
exec slapd -4VVV -u ${LDAPUSER} -g ${LDAPGROUP}         \
	-d ${DEBUG_LEVEL}                               \
	-f /etc/openldap/slapd.conf                     \
	-F /etc/openldap/slapd.d                        \
	-h "ldap://0.0.0.0:1389/ ldaps://0.0.0.0:1636/"
