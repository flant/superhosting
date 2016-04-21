conf_name = "#{container.name}-#{site.name}.conf"

config "/etc/nginx/sites/#{conf_name}", source: 'nginx_vhost'
on_reconfig 'nginx -t && service nginx reload'
