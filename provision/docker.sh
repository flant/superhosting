#!/usr/bin/env /bin/bash

homedir=${1:-.}

if [ $1 ]
then
  dockerfile=$1/dockerfile
else
  dockerfile=dockerfile
fi

docker build -t sx-base -f $dockerfile/base $homedir
docker build -t sx-almost-base -f $dockerfile/almost_base $homedir
docker build -t sx-mux -f $dockerfile/mux $homedir

docker tag -f sx-base superhosting/fcgi
docker tag -f sx-base superhosting/test
docker tag -f sx-almost-base superhosting/almostbase
docker tag -f sx-almost-base superhosting/cphp:5.3
docker tag -f sx-almost-base superhosting/cphp:5.5
docker tag -f sx-almost-base superhosting/cphp:5.6
docker tag -f sx-mux superhosting/php:5.3
docker tag -f sx-mux superhosting/php:5.5
docker tag -f sx-mux superhosting/php:5.6
docker tag -f sx-mux superhosting/mux