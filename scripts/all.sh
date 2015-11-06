#!/bin/bash

HOSTS=({node0{1..3},master0{3..1}}.secureworkslab.net)

#make sure to run ssh-keygen first

#Comment this section out after running it once
#for host in ${HOSTS[@]}; do
#  echo "Exchanging keys"
#  ssh-copy-id -o StrictHostKeyChecking=no root@$host
#done

for host in ${HOSTS[@]}; do

  #Comment this section out after running this script once
  echo "Setting up filesystem"
  scp setup_filesystem.sh $host:/root/setup_filesystem.sh
  ssh $host '/root/setup_filesystem.sh'

  echo "Setting up network"
  scp setup_network.sh $host:/root/setup_network.sh
  ssh $host '/root/setup_network.sh'

  #Uncomment this if you want to reboot everything
  # ssh $host 'reboot'
done
