config "#{container.lib.path}/supervisor/supervisord.conf"

mkdir "#{container.web.path}/supervisor"
mkdir "#{container.web.path}/logs/supervisor"

on_reconfig :container_restart
