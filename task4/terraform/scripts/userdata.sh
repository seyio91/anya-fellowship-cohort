#!/bin/bash

set -ex

sudo mkfs -t xfs /dev/xvdh  | sudo tee -a /home/ubuntu/init.log
sudo mkdir /data

sudo echo -e "UUID=$(sudo /usr/sbin/blkid -o value -s UUID /dev/xvdh) /data xfs defaults,nofail 0 2" | sudo tee  /home/ubuntu/tempfile
sudo cat /home/ubuntu/tempfile |sudo tee -a /etc/fstab
sudo mount -a

# starting polkadot service
sudo systemctl start ${service_name}.service
sudo systemctl enable ${service_name}.service

# cleanup
sudo rm -rf /home/ubuntu/tempfile
