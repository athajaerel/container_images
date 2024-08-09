#!/bin/bash
set -euo pipefail

eval ${PASS_ARGS}

LDAPUSER=_ldap
LDAPGROUP=_ldap

sed -i -e "s:ldap:${LDAPGROUP}:g" /etc/group
sed -i -e "s:^ldap:${LDAPUSER}:g" /etc/passwd

mv /var/lib/openldap/{openldap-,}data

#ldapadd -f entries.ldif -x -D "cn=Manager,dc=example,dc=com" -w secret

cat <<EOF >start.ldif
# Organization for Example Corporation
dn: dc=dev,dc=lab
objectClass: dcObject
objectClass: organization
dc: example
o: Example Corporation
description: The Example Corporation

# Organizational Role for Directory Manager
dn: cn=Director,dc=dev,dc=lab
objectClass: organizationalRole
cn: Director
description: Directory Manager
EOF

slapadd -l start.ldif \
	-f /etc/openldap/slapd.conf \
	-d 0 -b dc=dev,dc=lab

slaptest -u

# Create slapd.conf database
slapindex

# Create slapd.d database
slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d

chown -R ${LDAPUSER}:${LDAPGROUP} /etc/openldap/slapd.d
chown -R ${LDAPUSER}:${LDAPGROUP} /var/lib/openldap

more /etc/openldap/slapd.d/cn=config/cn=schema.ldif

# Zytrax's LDAP Guide: https://www.zytrax.com/books/ldap "... never
# has so much been written so incomprehensibly about a single
# topic..." :)

# slaptest -u

# https://www.openldap.org/doc/admin24/replication.html

