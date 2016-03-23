if container.mail.enabled?
  container.mail.password.safe_put!(['a'..'z', 'A'..'Z', 0..9].map(&:to_a).flatten.sample(30).join)

  config "#{container.config.path}/ssmtp/ssmtp.conf"
  config "/etc/postfix/postfwd.cf.d/#{container.name}.cf", source: 'postfwd_rules'

  on_reconfig "echo '#{container.mail.password}' | /usr/sbin/saslpasswd2 -u #{etc.smtp_hostname} -a smtpauth #{container.name} -p"
else
  on_reconfig "/usr/sbin/saslpasswd2 -u #{etc.smtp_hostname} -a smtpauth #{container.name} -d"
end

# TODO: on_reconfig 'cat $(ls -1 /etc/postfix/postfwd.cf.d/ | sort) > /etc/postfix/postfwd.cf && service postfwd reload'
