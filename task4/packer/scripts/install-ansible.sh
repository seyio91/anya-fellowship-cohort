#!/bin/bash
sudo apt update -y 
sudo apt install -y python3 python3-pip
sudo python3 -m pip install --upgrade pip wheel setuptools
sudo python3 -m pip install ansible==${ANSIBLE_VERSION}