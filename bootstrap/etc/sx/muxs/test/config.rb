mkdir "#{mux.lib.path}/test"
mkdir "#{mux.lib.path}/logs/test"

on_reconfig :container_restart
