module Superhosting
  module Controller
    class Site
      include Helper::States

      def install_data(name:, container_name:)
        container_mapper = @container_controller.index[container_name][:mapper]
        container_mapper.sites.f(name).create!
        site_lib_mapper = container_mapper.lib.web.f(name).create!

        chown_r!(container_name, container_name, site_lib_mapper.path)

        reindex_site(name: name, container_name: container_name)
        {}
      end

      def uninstall_data(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          container_mapper = index[name][:container_mapper]
          container_mapper.sites.f(name).delete!
          container_mapper.lib.web.f(name).delete!
          container_mapper.lib.sites.f(name).aliases.delete!

          reindex_site(name: name, container_name: container_mapper.name)
        end
        resp
      end

      def _config_options(name:, on_reconfig:, on_config:)
        mapper = index[name][:mapper]
        container_mapper = index[name][:container_mapper]
        registry_mapper = container_mapper.lib.registry.sites.f(name)

        @container_controller._config_options(
          name: container_mapper.name,
          on_reconfig: on_reconfig,
          on_config: on_config
        ).merge!(
          site: mapper,
          registry_mapper: registry_mapper
        )
      end
    end
  end
end
