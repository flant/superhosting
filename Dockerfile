FROM ubuntu:14.04
MAINTAINER flant <256@flant.com>
ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

RUN apt-get update -q
RUN apt-get install -y supervisor

RUN /bin/bash -lec "\
mkdir /.configs; \
cp /etc/passwd /.configs/etc-passwd; \
ln -fs /.configs/etc-passwd /etc/passwd; \
cp /etc/group /.configs/etc-group; \
ln -fs /.configs/etc-group /etc/group; \
mkdir /.configs/ssmtp; \
ln -fs /.configs/ssmtp /etc/ssmtp; \
mkdir /.configs/supervisor; \
rm -rf /etc/supervisor/conf.d; \
ln -fs /.configs/supervisor /etc/supervisor/conf.d; \
mkdir /web"
