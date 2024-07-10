#!/bin/bash
set -euo pipefail

eval ${PASS_ARGS}

#groupadd -g ${UID} ${USERNAME}
#useradd -r -u ${UID} -g ${USERNAME} ${USERNAME}

# permit to bind low ports without root
setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/kadmind
setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/krb5kdc
setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/kpropd

mkdir -p /var/krb5kdc
kdb5_util create -r ${realm} -s -P ${master_pw}

kadmin.local -r ${realm} addpol users
kadmin.local -r ${realm} addpol admin
kadmin.local -r ${realm} addpol hosts

kadmin.local -r ${realm} ank -pw ${admin_pw} -policy admin ${admin}@${realm}
