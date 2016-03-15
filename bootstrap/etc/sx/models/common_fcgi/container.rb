config "#{container.config_path}/supervisor/supervisord.conf"

mkdir "#{container.data_path}/supervisor"
mkdir "#{container.data_path}/logs/supervisor"

on_reconfig :container_restart
