#!/bin/bash
set -ex

/usr/sbin/kadmind &
/usr/sbin/krb5kdc -n &
#/usr/sbin/kpropd &  # ?

pause
