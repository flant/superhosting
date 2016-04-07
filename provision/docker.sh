#!/usr/bin/env /bin/bash

docker build -t sx-base -f dockerfile/base .
docker build -t sx-almost-base -f dockerfile/almost_base .
docker build -t sx-mux -f dockerfile/mux .

docker tag sx-base:latest superhosting/fcgi
docker tag sx-base:latest superhosting/test
docker tag sx-almost-base:latest superhosting/almostbase
docker tag sx-almost-base:latest superhosting/cphp:5.3
docker tag sx-almost-base:latest superhosting/cphp:5.5
docker tag sx-almost-base:latest superhosting/cphp:5.6
docker tag sx-mux:latest superhosting/php:5.3
docker tag sx-mux:latest superhosting/php:5.5
docker tag sx-mux:latest superhosting/php:5.6
docker tag sx-mux:latest superhosting/mux
docker tag sx-mux:latest superhosting/mux
