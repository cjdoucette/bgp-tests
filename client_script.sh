#!/bin/bash

sudo apt-get update
apt-get -y -q install bird2 net-tools

sudo ip addr add 172.31.1.184/24 dev ens6
sudo ip addr add 2600:1f16:354:f701:795:5efd:5335:9876/64 dev ens6
sudo ifconfig ens6 up

# Setup BIRD.
sudo pkill bird
cd ~
wget https://raw.githubusercontent.com/cjdoucette/bgp-tests/master/configs/client-bird.conf
sudo bird -c client-bird.conf
