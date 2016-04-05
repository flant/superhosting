config "#{container.config.path}/supervisor/supervisord.conf"

mkdir "#{container.web.path}/supervisor"
mkdir "#{container.web.path}/logs/supervisor"
