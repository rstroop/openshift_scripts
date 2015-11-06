#!/bin/bash

#Use the squid proxy for the first run, and then update the proxy to point at the service address of your squidy app and run this again later
PROXY="http://squid.internal.secureworks.net:3128"
#PROXY="http://<proxy_svc_ip>:3128"
NO_PROXY="'<this_ip>,.secureworks.net,.secureworks.com,.secureworkslab.com,.secureworkslab.net,.google.internal,localhost,localhost6'"

REGISTRY=hostname:port

FILES=(/etc/sysconfig/docker /etc/sysconfig/openshift-master /etc/sysconfig/openshift-node)

######################################
######################################

#DO NOT EDIT ANYTHING BELOW THESE LINES

######################################
######################################

for filename in ${FILES[@]}; do
  if [[ -e $filename ]]; then
    sed -i '/.*PROXY.*/d' $filename
    echo HTTP_PROXY=$PROXY >> $filename
    echo HTPPS_PROXY=$PROXY >> $filename
    echo NO_PROXY=$NO_PROXY >> $filename
  fi
done

#Set up docker rules
sed -i 's/^OPTIONS.*/OPTIONS='\''--log-level=warn --selinux-enabled --insecure-registry 172\.18\.0\.0\/16 --insecure-registry '$REGISTRY\''/g' /etc/sysconfig/docker
sed -i 's/^ADD_REGISTRY.*/ADD_REGISTRY='\''--add-registry '$REGISTRY\''/g' /etc/sysconfig/docker
sed -i 's/^# BLOCK_REGISTRY.*/BLOCK_REGISTRY='\''--block-registry public'\''/g' /etc/sysconfig/docker

#Set up docker proxy
echo "Setting Docker proxy environment variables"
mkdir -p /etc/systemd/system/docker.service.d

cat <<EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=$PROXY" "HTTPS_PROXY=$PROXY" "NO_PROXY=$NO_PROXY"
EOF

cat <<EOF > /etc/profile.d/proxy.sh
export ftp_proxy=$PROXY
export http_proxy=$PROXY
export https_proxy=$PROXY
export no_proxy=$NO_PROXY
EOF

#Allow Multicast
iptables -I INPUT -i eth0 -d 224.0.0.18/32 -j ACCEPT
service iptables save

printf "%s\n" "systemctl daemon-reload"
systemctl daemon-reload
printf "%s\n" "systemctl restart docker"
systemctl restart docker
printf "%s\n" "systemctl restart openshift-node"
systemctl restart openshift-node
printf "%s\n" "systemctl restart openshift-master"
systemctl restart openshift-master
