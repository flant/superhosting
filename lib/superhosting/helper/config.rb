module Superhosting
  module Helper
    module Config
      def unconfigure(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          case mapper_type(index[name][:mapper])
            when 'container'
              registry_mapper = index[name][:mapper].lib.registry.container
            when 'site'
              registry_mapper = index[name][:container_mapper].lib.registry.sites.f(name)
            else
              raise NetStatus::Exception, error: :logical_error, code: :mapper_type_not_supported, data: { name: type }
          end

          unless registry_mapper.nil?
            registry_mapper.lines.each { |path| PathMapper.new(path).delete! }
            registry_mapper.delete!
          end
        end
        resp
      end

      def apply(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          _config(name: name, on_reconfig: true, on_config: false)
        end
        resp
      end

      def unapply(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          apply(name: name)
        end
        resp
      end

      def configure_with_apply(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          _config(name: name, on_reconfig: true, on_config: true)
        end
        resp
      end

      def unconfigure_with_unapply(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          unconfigure(name: name)
          unapply(name: name)
        else
          resp
        end
      end

      def _config(name:, on_reconfig:, on_config:)
        mapper = index[name][:mapper]
        options = _config_options(name: name, on_reconfig: on_reconfig, on_config: on_config)
        registry_mapper = options.delete(:registry_mapper)
        registry_files = []

        mapper.f('config.rb', overlay: false).reverse_each do |config|
          ex = ConfigExecutor.new(options)
          ex.execute(config)
          ex.run_commands
          registry_files += ex.registry_files
        end

        _save_registry!(registry_mapper, registry_files) if on_config
      end

      def _config_options(name:, on_reconfig:, on_config:)
        {}
      end

      def _save_registry!(registry_mapper, registry_files)
        old_configs = registry_mapper.lines
        unless (old_configs -= registry_files).empty?
          debug_block(desc: { code: :deleting_old_configs }) do
            old_configs.each { |file| PathMapper.new(file).delete! }
          end
        end
        registry_mapper.override!(registry_files.join("\n"))
      end
    end
  end
end
