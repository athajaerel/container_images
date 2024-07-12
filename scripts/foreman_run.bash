#!/bin/bash
set -ex

# This is tricky. Need to do this for regular podman AND kubernetes.
# Might have to be a manual configuration.
# This is helpful: https://github.com/ohadlevy/foreman-kube
# This is not: https://github.com/theforeman/foreman/blob/develop/Dockerfile

# Modify cat <<EOF >>/etc/foreman-installer/scenarios.d/foreman-answers.yaml

#  foreman_base_url: https://${fqdn}
#  tftp_server_name: ${foreman_tftp_server}
#  dhcp_interface: ${foreman_nic}
#  dhcp_gateway: ${foreman_gateway}
#  dhcp_range: ${foreman_dhcp_range_str}
#  dhcp_nameservers: ${foreman_nameserver}
#  dns_interface: ${foreman_nic}
#  dns_zone: ${domain}
#  dns_reverse: ${reverse_zone}
#  dns_forwarders: ${foreman_nameserver}

foreman-installer -v

# Run Foreman
bundle exec bin/rails server
