#!/bin/bash
set -euo pipefail

eval ${PASS_ARGS}

wget https://${puppet_site}/${puppet_deb} -O /tmp/${puppet_deb}
apt-get install /tmp/${puppet_deb}

wget https://${foreman_site}/${foreman_key} \
	-O /etc/apt/trusted.gpg.d/${foreman_key}

cat <<EOF >>/etc/apt/sources.list.d/foreman.list
deb http://${foreman_site}/ ${debian_release} ${foreman_version}
deb http://${foreman_site}/ plugins ${foreman_version}
EOF

apt-get update
apt-get -y install foreman-installer
