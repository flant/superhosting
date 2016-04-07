#!/usr/bin/env /bin/bash

curl -s https://packagecloud.io/install/repositories/flant/pam_docker/script.deb.sh | sudo bash
apt-get update
apt-get install -y docker-engine pam-docker

gpasswd -a vagrant docker
service docker restart

docker build -t sx-base -f dockerfile/base .
docker build -t sx-almost-base -f dockerfile/almost_base .
docker build -t sx-mux -f dockerfile/mux .

docker tag sx-base superhosting/fcgi
docker tag sx-base superhosting/test
docker tag sx-almost-base superhosting/almostbase
docker tag sx-almost-base superhosting/cphp:5.3
docker tag sx-almost-base superhosting/cphp:5.5
docker tag sx-almost-base superhosting/cphp:5.6
docker tag sx-mux superhosting/php:5.3
docker tag sx-mux superhosting/php:5.5
docker tag sx-mux superhosting/php:5.6
docker tag sx-mux superhosting/mux
docker tag sx-mux superhosting/mux
