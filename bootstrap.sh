#!/usr/bin/env /bin/bash

apt-get update
apt-get install -y build-essential libpam0g-dev apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main' > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-engine

cd /tmp
git clone https://github.com/flant/pam_docker.git
cd pam_docker
make
make install-ubuntu-14.04
