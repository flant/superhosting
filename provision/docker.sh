#!/usr/bin/env /bin/bash.

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