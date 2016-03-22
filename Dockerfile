FROM ubuntu:14.04
MAINTAINER flant <256@flant.com>

RUN apt-get update -q
RUN apt-get install -y supervisor

RUN /bin/bash -lec "\
mkdir /.config; \
cp /etc/passwd /.config/etc-passwd; \
ln -fs /.config/etc-passwd /etc/passwd; \
cp /etc/group /.config/etc-group; \
ln -fs /.config/etc-group /etc/group; \
mkdir /.config/ssmtp; \
ln -fs /.config/ssmtp /etc/ssmtp; \
mkdir /web"
