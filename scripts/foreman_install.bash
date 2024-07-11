#!/bin/bash
set -euo pipefail

eval ${PASS_ARGS}

#Repositories
#
#Enable Puppet's 7.x repository:
#
#sudo apt-get -y install ca-certificates
#cd /tmp && wget https://apt.puppet.com/puppet7-release-bullseye.deb
#sudo apt-get install /tmp/puppet7-release-bullseye.deb
#
#Enable the Foreman repositories:
#
#sudo wget https://deb.theforeman.org/foreman.asc -O /etc/apt/trusted.gpg.d/foreman.asc
#echo "deb http://deb.theforeman.org/ bullseye 3.11" | sudo tee /etc/apt/sources.list.d/foreman.list
#echo "deb http://deb.theforeman.org/ plugins 3.11" | sudo tee -a /etc/apt/sources.list.d/foreman.list
#
#Downloading the installer
#
#sudo apt-get update && sudo apt-get -y install foreman-installer
#
#Running the installer
#Ensure that ping $(hostname -f) shows the real IP address, not 127.0.1.1. Change or remove this entry from /etc/hosts if present.
#
#The installation run is non-interactive, but the configuration can be customized by supplying any of the options listed in foreman-installer --help, or by running foreman-installer -i for interactive mode. More examples are given in the Installation Options section. Adding -v will disable the progress bar and display all changes. To run the installer, execute:
#
#sudo foreman-installer
#
#After it completes, the installer will print some details about where to find Foreman and the Smart Proxy. Output should be similar to this:
#
#  * Foreman is running at https://theforeman.example.com
#      Initial credentials are admin / 3ekw5xtyXCoXxS29
#  * Foreman Proxy is running at https://theforeman.example.com:8443
#  The full log is at /var/log/foreman-installer/foreman-installer.log
