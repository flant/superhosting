#!/usr/bin/env /bin/bash

echo mysql-apt-config mysql-apt-config/enable-repo select mysql-5.7-dmr | sudo debconf-set-selections
wget http://dev.mysql.com/get/mysql-apt-config_0.2.1-1ubuntu12.04_all.deb
sudo dpkg --install mysql-apt-config_0.2.1-1ubuntu12.04_all.deb
sudo apt-get update -q
sudo apt-get install -q -y -o Dpkg::Options::=--force-confnew mysql-server
echo "USE mysql;\nALTER USER 'root'@'localhost' IDENTIFIED BY 'root';\nFLUSH PRIVILEGES;\n" | mysql -u root