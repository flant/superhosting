conf_name = "#{container.name}-#{site.name}.conf"

config "/etc/apache/sites/#{conf_name}", source: "apache_vhost" if site.use_apache?
on_reconfig "apache2ctl configtest && service apache2 reload"

config "/etc/nginx/sites/#{conf_name}", source: "nginx_vhost"
on_reconfig "nginx -t && service nginx reload"

# TODO config "#{mux.config_path}/pools/#{conf_name}", source: "php_fpm_pool"
on_reconfig 'service php5-fpm reload', in: :mux
