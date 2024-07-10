#!/bin/bash
set -euo pipefail

eval ${PASS_ARGS}

domain=$(<<<${realm} tr '[:upper:]' '[:lower:]')

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
        kdc = localhost:88
        admin_server = localhost:749
        master_kdc = localhost:88
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

krb5kdc -n -P /var/run/krb5-kdc.pid &
sleep 15

cat /etc/krb5.conf /var/krb5kdc/kadm5.acl /var/krb5kdc/kprop.acl

cat <<EOF >./expect.exp
spawn /usr/bin/kinit -c ${CCFILE} -S ${KADM_PRINC} ${admin}@${realm}
expect "Password for ${admin}@${realm}: "
send -- "${admin_pw}\r"
expect eof
EOF
expect ./expect.exp
rm ./expect.exp
#xbps-remove -y expect

klist -c ${CCFILE}
kadmin.local -c ${CCFILE} ktadd -k ${KADM_KEYTAB} ${KCHP_PRINC} ${KADM_PRINC}
kdestroy -A -c ${CCFILE}

chown -R ${UID}:${UID} /etc
chown -R ${UID}:${UID} /usr
chown -R ${UID}:${UID} /var
