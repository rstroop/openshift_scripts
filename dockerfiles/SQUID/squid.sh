#!/bin/bash

sed -i 's#acl OSENet  dst .*#acl OSENet  dst '${OSENET:-10.0.0.0/8}'#' ${SQUIDCONF:-/etc/squid/squid.conf}
sed -i 's#acl DCKRNet dst .*#acl DCKRNet dst '${DOCKERNET:-172.16.0.0/12}'#' ${SQUIDCONF:-/etc/squid/squid.conf}
sed -i 's#acl DCKRBr  dst .*#acl DCKRBr  dst '${DOCKERBRIDGE:-192.168.0.0/16}'#' ${SQUIDCONF:-/etc/squid/squid.conf}

sed -i 's#cache_peer squidy #cache_peer '${UPSTREAM:-squid.internal.secureworks.net}' #' ${SQUIDCONF:-/etc/squid/squid.conf}

exec /usr/sbin/squid -d 1 -f ${SQUIDCONF:-/etc/squid/squid.conf} -N
