#!/bin/bash
set -euo pipefail

eval ${PASS_ARGS}

#DETECTED_IP=$(ping ${HOSTNAME} -c 1 | head -n1 | awk -F[\ \(\)] '{print $4}')

#fqdn=$(hostname -f)
#foreman_tftp_server=${DETECTED_IP}
#foreman_nic="eth0"
#foreman_gateway=$(ip -r | grep default | cut -d\  -f 3)
#foreman_dhcp_range_str="1.2.3.1 1.2.3.7"
#foreman_nameserver=${DETECTED_IP}
#domain=$(hostname -d)
#reverse_zone="4.3.2.1.in-addr.arpa"

# maybe copy settings from another host rather than use foreman-installer?

fqdn=foreman.dev.lab
foreman_tftp_server=10.20.0.163
foreman_nic="eth0"
foreman_gateway=10.20.0.253
foreman_dhcp_range_str="10.20.0.110 10.20.0.120"
foreman_nameserver=10.20.0.163
domain=dev.lab
reverse_zone="0.20.10.in-addr.arpa"

#hostnamectl set-hostname ${fqdn}
echo "${fqdn}" >/etc/hostname

mv /bin/hostname /bin/hostname.old
cat <<EOF >/bin/hostname
#!/bin/sh
#echo "${fqdn}"
facter fqdn
EOF
chmod a+x /bin/hostname

cat <<EOF >/etc/hosts
127.0.0.1 localhost
10.20.0.163 foreman.dev.lab
EOF

cat <<EOF >>/etc/foreman-installer/scenarios.d/foreman-answers.yaml
---
foreman: {}
foreman::cli: true
foreman::cli::ansible: false
foreman::cli::azure: false
foreman::cli::discovery: false
foreman::cli::google: false
foreman::cli::kubevirt: false
foreman::cli::openscap: false
foreman::cli::puppet: true
foreman::cli::remote_execution: false
foreman::cli::ssh: false
foreman::cli::tasks: false
foreman::cli::templates: false
foreman::cli::webhooks: false
foreman::compute::ec2: false
foreman::compute::libvirt: false
foreman::compute::openstack: false
foreman::compute::ovirt: false
foreman::compute::vmware: false
foreman::plugin::acd: false
foreman::plugin::ansible: false
foreman::plugin::azure: false
foreman::plugin::bootdisk: false
foreman::plugin::default_hostgroup: false
foreman::plugin::dhcp_browser: false
foreman::plugin::discovery: false
foreman::plugin::dlm: false
foreman::plugin::expire_hosts: false
foreman::plugin::git_templates: false
foreman::plugin::google: false
foreman::plugin::host_extra_validator: false
foreman::plugin::kubevirt: false
foreman::plugin::leapp: false
foreman::plugin::monitoring: false
foreman::plugin::netbox: false
foreman::plugin::omaha: false
foreman::plugin::openscap: false
foreman::plugin::ovirt_provision: false
foreman::plugin::proxmox: false
foreman::plugin::puppet: true
foreman::plugin::puppetdb: false
foreman::plugin::remote_execution: false
foreman::plugin::remote_execution::cockpit: false
foreman::plugin::rescue: false
foreman::plugin::salt: false
foreman::plugin::snapshot_management: false
foreman::plugin::statistics: false
foreman::plugin::tasks: false
foreman::plugin::templates: false
foreman::plugin::vault: false
foreman::plugin::webhooks: false
foreman::plugin::wreckingball: false
foreman_proxy:
  foreman_base_url: https://${fqdn}
  tftp: true
  tftp_server_name: ${foreman_tftp_server}
  dhcp: true
  dhcp_interface: ${foreman_nic}
  dhcp_gateway: ${foreman_gateway}
  dhcp_range: ${foreman_dhcp_range_str}
  dhcp_nameservers: ${foreman_nameserver}
  dns: true
  dns_interface: ${foreman_nic}
  dns_zone: ${domain}
  dns_reverse: ${reverse_zone}
  dns_forwarders: ${foreman_nameserver}
foreman_proxy::plugin::acd: false
foreman_proxy::plugin::ansible: false
foreman_proxy::plugin::dhcp::infoblox: false
foreman_proxy::plugin::dhcp::remote_isc: false
foreman_proxy::plugin::discovery: false
foreman_proxy::plugin::dns::infoblox: false
foreman_proxy::plugin::dns::powerdns: false
foreman_proxy::plugin::dns::route53: false
foreman_proxy::plugin::dynflow: true
foreman_proxy::plugin::monitoring: false
foreman_proxy::plugin::omaha: true
foreman_proxy::plugin::openscap: false
foreman_proxy::plugin::remote_execution::script: false
foreman_proxy::plugin::salt: false
foreman_proxy::plugin::shellhooks: false
puppet:
  server: true
  server_jvm_extra_args:
  - "-Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger"
  - "-XX:ReservedCodeCacheSize=512m"
apache::mod::status: false
EOF

cat <<EOF >>/etc/foreman-installer/scenarios.d/foreman-answers.yaml
EOF

more /etc/hosts

foreman-installer -v

apt-get remove -y wget facter
apt-get autoremove -y
