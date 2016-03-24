module Superhosting
  module Controller
    class Site
      include Helper::States

      def install_data(name:, container_name:)
        if (resp = self.adding_validation(name: name)).net_status_ok? and
            (resp = @container_controller.existing_validation(name: container_name)).net_status_ok?
          container_mapper = @container_controller.index[container_name][:mapper]
          container_mapper.sites.f(name).create!
          site_lib_mapper = container_mapper.lib.web.f(name).create!

          chown_r(container_name, container_name, site_lib_mapper.path)

          self.reindex_site(name: name, container_name: container_name)
        end
        resp
      end

      def uninstall_data(name:)
        if self.index.include? name
          container_mapper = self.index[name][:container_mapper]
          container_mapper.sites.f(name).delete!
          container_mapper.lib.web.f(name).delete!

          self.reindex_site(name: name, container_name: container_mapper.name)
        end

        {}
      end

      def configure(name:)
        self._config(name: name, on_reconfig: false, on_config: true)

        {}
      end

      def unconfigure(name:)
        container_mapper = self.index[name][:container_mapper]
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

        {}
      end

      def _config(name:, on_reconfig:, on_config:)
        mapper = self.index[name][:mapper]
        mapper.f('config.rb', overlay: false).reverse.each do |config|
          ex = ScriptExecutor::Site.new(self._config_options(name: name, on_reconfig: on_reconfig, on_config: on_config))
          ex.execute(config)
          ex.run_commands
        end
      end

      def _reconfig(name:)
        self.unconfigure(name: name)
        self.configure(name: name)
      end

      def _config_options(name:, on_reconfig:, on_config:)
        mapper = self.index[name][:mapper]
        container_mapper = self.index[name][:container_mapper]
        registry_mapper = container_mapper.lib.registry.sites.f(name)

        @container_controller._config_options(name: container_mapper.name, on_reconfig: on_reconfig, on_config: on_config).merge! ({
            site: mapper,
            registry_mapper: registry_mapper
        })
      end
    end
  end
end