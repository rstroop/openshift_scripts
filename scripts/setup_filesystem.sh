#!/bin/bash

DISK="/dev/sdc"

######################
######################

#DO NOT EDIT BELOW HERE

######################
######################

echo "Installing OpenShift dependencies"
yum -y install wget git net-tools bind-utils iptables-services bridge-utils python-virtualenv gcc

echo "Installing Docker..."
yum -y install docker

echo "Configuring Docker storage..."
vgremove -f docker-vg

echo "Creating Docker partition"
parted -s $DISK mklabel gpt
parted -s $DISK mkpart part1 '1 100%'

echo "Creating volume group(docker-vg)"
pvcreate ${DISK}1
vgcreate docker-vg ${DISK}1

#segregate storage for etcd in /var/lib/openshift echo "Creating volume for /var/lib/openshift"
lvcreate -L 3G -n lv_lib_ose vg_root
mkfs.ext4 /dev/vg_root/lv_lib_ose
mkdir /var/lib/openshift
mount /dev/vg_root/lv_lib_ose /var/lib/openshift
sed -i '/\/var\/lib\/openshift/d' /etc/fstab
echo "/dev/mapper/vg_root-lv_lib_ose /var/lib/openshift       ext4      defaults     1 1" >> /etc/fstab

echo "Adding the VG to docker config file"
echo "VG=docker-vg" > /etc/sysconfig/docker-storage-setup

echo "Running Setup"
docker-storage-setup

echo "Verifying pool exists"
lvs
echo "Does docker-pool exist on docker-vg?"
sleep 10

echo "Clearing and restarting docker"
systemctl stop docker
rm -rf /var/lib/docker/*
systemctl restart docker

#Add man in the middle capability >:-)

update-ca-trust enable
curl -sk https://host/name.cer > /etc/pki/ca-trust/source/anchors/name.crt
update-ca-trust extract

#Set up logs

sed -i '/.*openshift.*/d' /etc/rsyslog.conf
sed -i '/.*docker.*/d' /etc/rsyslog.conf
sed -i 's/.*RULES.*/#### RULES ####\n:programname, contains, \"openshift\"\t\t\t\/var\/log\/openshift\n:programname, contains, \"openshift\" ~\n:programname, contains, \"docker\"\t\t\t\/var\/log\/openshift\n:programname, contains, \"docker\" ~/g' /etc/rsyslog.conf

cat <<EOF > /etc/logrotate.d/openshift
/var/log/openshift {
    rotate 2
    daily
    compress
}
EOF

systemctl restart rsyslog
