module Superhosting
  module Controller
    class Mux
      include Helper::States

      def install_data(name:)
        mapper = self.index[name].mapper
        mapper.config.f('etc-group').append_line!('root:x:0:')
        mapper.config.f('etc-passwd').append_line!('root:x:0:0:root:/root:/bin/bash')
        {}
      end

      def uninstall_data(name:)
        mapper = self.index[name].mapper
        mapper.config.delete!
        mapper.lib.delete!
        {}
      end

      def configure_with_apply(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          super
        else
          resp
        end
      end

      def run(name:)
        mapper = index[name].mapper
        @container_controller._refresh_container(mapper: mapper, docker_options: _docker_options(mapper: mapper))
        {}
      end

      def stop(name:)
        mapper = index[name].mapper
        @container_controller._delete_docker(name: mapper.container_name)
        {}
      end

      def _config_options(name:, **_kwargs)
        mapper = index[name].mapper
        registry_mapper = mapper.lib.registry.f('mux')
        super.merge!(mux: mapper, registry_mapper: registry_mapper)
      end

      def _docker_options(mapper:)
        command_options, image, command = @container_controller._collect_docker_options(mapper: mapper).net_status_ok![:data]
        command_options << "--volume #{mapper.config.path}/:/.config:ro"
        [command_options, image, command]
      end
    end
  end
end
