#!/bin/bash

cd /home/ubuntu
su ubuntu -c 'git clone --recursive --branch bgp_aws_tests http://github.com/cjdoucette/gatekeeper.git'
cd gatekeeper

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y -q install git clang devscripts doxygen hugepages build-essential linux-headers-`uname -r` libmnl0 libmnl-dev libkmod2 libkmod-dev libnuma-dev libelf1 libelf-dev libc6-dev-i386 autoconf flex bison libncurses5-dev libreadline-dev

apt-get -y -q install exuberant-ctags

echo 1024 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

. setup.sh
echo "export RTE_SDK=${RTE_SDK}" >> /home/ubuntu/.profile
echo "export RTE_TARGET=${RTE_TARGET}" >> /home/ubuntu/.profile
su ubuntu -c 'source /home/ubuntu/.profile'

dependencies/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 00:06.0
dependencies/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 00:07.0

su ubuntu -c 'make'
su ubuntu -c 'ctags -R .'
./build/gatekeeper -- -l gatekeeper.log &

# Setup BIRD.
cd ~
wget https://raw.githubusercontent.com/cjdoucette/bgp-tests/master/gk-bird.conf
sudo bird -c gk-bird.conf
