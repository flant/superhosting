#!/usr/bin/env /bin/bash

curl -s https://packagecloud.io/install/repositories/flant/pam_docker/script.deb.sh | sudo bash
apt-get update
apt-get install -y docker-engine pam-docker

gpasswd -a vagrant docker
service docker restart

apt-get update
apt-get install nginx sasl2-bin apache2 -y
sed -i 's/Listen 80/Listen 81/g' /etc/apache2/ports.conf

curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | sudo bash -s stable

echo 'source /etc/profile.d/rvm.sh' >> /etc/bash.bashrc
echo 'export BUNDLE_GEMFILE=/vagrant/Gemfile' >> /etc/bash.bashrc
sed -ir 's/# *(\".*history-search)/\1/' /etc/inputrc

source /etc/profile.d/rvm.sh

rvm group add rvm vagrant
rvm install 2.2.1 --quiet-curl
rvm --default use 2.2.1
gem install bundler

cd /vagrant
bundle install

cp -r /vagrant/bootstrap/* /