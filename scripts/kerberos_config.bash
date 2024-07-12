#!/bin/bash
set -euo pipefail

eval ${PASS_ARGS}

domain=$(<<<${realm} tr '[:upper:]' '[:lower:]')

# use a high port while building
HIPORT=10088
LOPORT=88

CCFILE=/dev/shm/krb5cc_install
KADM_KEYTAB=/var/krb5kdc/kadm5.keytab
KADM_PRINC=kadmin/admin@${realm}
KCHP_PRINC=kadmin/changepw@${realm}

cat <<EOF >/etc/krb5.conf
[logging]
    default = STDERR
    kdc = STDERR
    admin_server = STDERR

[libdefaults]
    default_realm = ${realm}
    dns_lookup_kdc = false
    dns_lookup_realm = false
    rdns = false
    default_ccache_name = /dev/shm/krb5cc_%{uid}
    spake_preauth_groups = edwards25519

[realms]
    ${realm} = {
        kdc = localhost:${HIPORT}
        admin_server = localhost:749
        master_kdc = localhost:${HIPORT}
        default_domain = ${domain}
        kpasswd_server = localhost:464
    }

[domain_realm]
    .${domain} = ${realm}
    ${domain} = ${realm}
EOF

cat <<EOF >/var/krb5kdc/kadm5.acl
${admin}@${realm} *
*/${admin_type}@${realm} *
EOF

cat <<EOF >/var/krb5kdc/kprop.acl
host/localhost.${domain}@${realm}
EOF

krb5kdc -n -p ${HIPORT} -P /var/run/krb5-kdc.pid &
sleep 2

# check if port ${HIPORT} is open, fail if not
N=$(ss -H4lnt state listening src 0.0.0.0:${HIPORT} | wc -l)
[ ${N} -eq 0 ] && exit 1
echo "Port detected ok"
sleep 2

cat <<EOF >./expect.exp
spawn /usr/bin/kinit -c ${CCFILE} -S ${KADM_PRINC} ${admin}@${realm}
expect "Password for ${admin}@${realm}: "
send -- "${admin_pw}\r"
expect eof
EOF
expect ./expect.exp
rm ./expect.exp

klist -c ${CCFILE}
kadmin.local -c ${CCFILE} ktadd -k ${KADM_KEYTAB} ${KCHP_PRINC} ${KADM_PRINC}
kdestroy -A -c ${CCFILE}

kill $(more /var/run/krb5-kdc.pid)

# Normalise ports
sed -i -e "s;localhost:${HIPORT};localhost:${LOPORT};g" /etc/krb5.conf

chown -R ${UID}:${UID} /etc
chown -R ${UID}:${UID} /usr
chown -R ${UID}:${UID} /var
