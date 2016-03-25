module Superhosting
  module Helper
    module Config
      def configure(name:)
        self._config(name: name, on_reconfig: false, on_config: true)
        {}
      end

      def unconfigure(name:)
        case self.index[name][:mapper].parent.name
          when 'containers'
            container_mapper = self.index[name][:mapper]

            site_controller = self.get_controller(Superhosting::Controller::Site)
            sites = container_mapper.sites.grep_dirs.map { |n| n.name }
            sites.each do |site_name|
              unless (resp = site_controller.unconfigure(name: site_name)).net_status_ok?
                return resp
              end
            end
          when 'sites'
            container_mapper = self.index[name][:container_mapper]
          else raise NetStatus::Exception, { error: :logical_error, code: :mapper_type_not_supported, data: { name: type } }
        end

        unless (registry_container_mapper = container_mapper.lib.registry.sites.f(name)).nil?
          registry_container_mapper.lines.each {|path| PathMapper.new(path).delete! }
          registry_container_mapper.delete!
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

      def reconfig(name:)
        self.unconfigure(name: name)
        self.configure(name: name)
      end

      def _config(name:, on_reconfig:, on_config:)
        mapper = self.index[name][:mapper]
        mapper.f('config.rb', overlay: false).reverse.each do |config|
          options = self._config_options(name: name, on_reconfig: on_reconfig, on_config: on_config)

          if on_config
            registry_mapper = options[:registry_mapper]
            dummy_registry_mapper = options[:registry_mapper] = registry_mapper.parent.f(".#{registry_mapper.name}.tmp")
            old_configs = registry_mapper.lines
          end

          ex = ConfigExecutor.new(options)
          ex.execute(config)
          ex.run_commands

          if on_config
            unless (old_configs = old_configs - dummy_registry_mapper.lines).empty?
              self.debug('Deleting old configs...')
              old_configs.each { |file| PathMapper.new(file).delete! }
            end
            dummy_registry_mapper.override!(registry_mapper.path)
          end
        end
      end

      def _config_options(name:, on_reconfig:, on_config:)
        {}
      end
    end
  end
end
