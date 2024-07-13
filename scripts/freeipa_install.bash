#!/bin/bash
set -euo pipefail

eval ${PASS_ARGS}

fqdn=${hostname}.${domain}

ipa_answers=$(mktemp)

tee ${ipa_answers} <<EOF
yes
${fqdn}
${domain}
$(<<<${domain} tr '[:lower:]' '[:upper:]')
${master_pw}
${master_pw}
${admin_pw}
${admin_pw}
yes
no
8.8.8.8
8.8.4.4

yes
yes

EXAMPLE
yes
pool.ntp.org

yes
EOF

systemctl mask rpc-gssd.service
systemctl mask chrony.service
systemctl mask chronyd.service

<${ipa_answers} ipa-server-install
