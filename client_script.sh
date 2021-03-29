#!/bin/bash

sudo apt-get update
apt-get -y -q install bird2

sudo ip addr add 172.31.1.184/24 dev ens6
sudo ip addr -f inet6 add 2600:1f16:354:f701:795:5efd:5335:9876/64 dev ens6
sudo ifconfig ens6 up

# Setup BIRD.
cd ~
wget https://raw.githubusercontent.com/cjdoucette/bgp-tests/master/client-bird.conf
sudo bird -c client-bird.conf
