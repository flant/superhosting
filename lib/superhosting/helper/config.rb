module Superhosting
  module Helper
    module Config
      def _config(name:, on_reconfig:, on_config:)
        mapper = self.index[name][:mapper]
        mapper.f('config.rb', overlay: false).reverse.each do |config|
          ex = ConfigExecutor.new(self._config_options(name: name, on_reconfig: on_reconfig, on_config: on_config))
          ex.execute(config)
          ex.run_commands
        end
      end

      def _reconfig(name:)
        self.unconfigure(name: name)
        self.configure(name: name)
      end
    end
  end
end
