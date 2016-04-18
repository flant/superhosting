module Superhosting
  module Helper
    module Config
      def configure(name:)
        self._config(name: name, on_reconfig: false, on_config: true)
        {}
      end

      def unconfigure(name:)
        case get_mapper_type(self.index[name][:mapper])
          when 'container'
            registry_mapper = self.index[name][:mapper].lib.registry.container
          when 'site'
            registry_mapper = self.index[name][:container_mapper].lib.registry.sites.f(name)
          else raise NetStatus::Exception, { error: :logical_error, code: :mapper_type_not_supported, data: { name: type } }
        end

        unless registry_mapper.nil?
          registry_mapper.lines.each {|path| PathMapper.new(path).delete! }
          registry_mapper.delete!
        end
        {}
      end

      def apply(name:)
        self._config(name: name, on_reconfig: true, on_config: false)
        {}
      end

      def unapply(name:)
        apply(name: name)
      end

      def configure_with_apply(name:)
        self._config(name: name, on_reconfig: true, on_config: true)
        {}
      end

      def unconfigure_with_unapply(name:)
        self.unconfigure(name: name)
        self.unapply(name: name)
      end

      def reconfig(name:)
        self.unconfigure(name: name)
        self.configure(name: name)
      end

      def _config(name:, on_reconfig:, on_config:)
        mapper = self.index[name][:mapper]
        options = self._config_options(name: name, on_reconfig: on_reconfig, on_config: on_config)
        registry_mapper = options.delete(:registry_mapper)
        registry_files = []

        mapper.f('config.rb', overlay: false).reverse.each do |config|
          ex = ConfigExecutor.new(options)
          ex.execute(config)
          ex.run_commands
          registry_files += ex.registry_files
        end

        self._save_registry!(registry_mapper, registry_files) if on_config
      end

      def _config_options(name:, on_reconfig:, on_config:)
        {}
      end

      def _save_registry!(registry_mapper, registry_files)
        old_configs = registry_mapper.lines
        unless (old_configs = old_configs - registry_files).empty?
          self.debug_block(desc: { code: :deleting_old_configs }) do
            old_configs.each { |file| PathMapper.new(file).delete! }
          end
        end
        registry_mapper.override!(registry_files.join("\n"))
      end
    end
  end
end