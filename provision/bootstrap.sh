#!/usr/bin/env /bin/bash

if [ $1 ]
then
  cp -r $1/bootstrap/* /
else
  cp -r bootstrap/* /
fi

apt-get install nginx sasl2-bin apache2 -y
sed -i 's/Listen 80/Listen 81/g' /etc/apache2/ports.conf