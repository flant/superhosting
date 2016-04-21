#!/usr/bin/env /bin/bash

curl -s https://packagecloud.io/install/repositories/flant/pam_docker/script.deb.sh | bash
apt-get update
apt-get install -y pam-docker