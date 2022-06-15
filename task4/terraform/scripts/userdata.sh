#!/bin/bash

set -ex

sudo mkfs -t xfs /dev/xvdh  >> /home/ubuntu/init.log
sudo mkdir /data >>  /home/ubuntu/init.log
sudo /usr/sbin/blkid -o value -s UUID /dev/xvdh >> /home/ubuntu/testfile
sudo cat /home/ubuntu/testfile
sudo echo -e "UUID=$(sudo /usr/sbin/blkid -o value -s UUID /dev/xvdh) /data xfs defaults,nofail 0 2" > /home/ubuntu/tempfile
sudo cat /home/ubuntu/tempfile |sudo tee -a /etc/fstab
sudo cat /etc/fstab >>  /home/ubuntu/init.log
sudo mount -a

sudo systemctl start ${service_name}.service
sudo systemctl enable ${service_name}.service