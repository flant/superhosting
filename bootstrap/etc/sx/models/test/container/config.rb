config "#{container.config.path}/supervisor/supervisord.conf"

mkdir "#{container.web.path}/supervisor", user: "#{container.name}_test", group: container.name
mkdir "#{container.web.path}/logs/supervisor", mode: 0777
