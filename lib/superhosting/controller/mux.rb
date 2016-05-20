module Superhosting
  module Controller
    class Mux < Base
      def _delete(name:)
        lib_mapper = index[name].mapper.lib

        states = {
          up: { action: :stop, undo: :run, next: :configuration_applied },
          configuration_applied: { action: :unconfigure_with_unapply, undo: :configure_with_apply, next: :data_installed },
          data_installed: { action: :uninstall_data, undo: :install_data }
        }

        on_state(state_mapper: lib_mapper, states: states, name: name)
      end

      def reconfigure(name:)
        if (resp = useable_validation(name: name)).net_status_ok?
          _reconfigure(name: name)
          index_mux_containers(name: name).each do |container_name|
            break unless (resp = @container_controller.reconfigure(name: container_name)).net_status_ok?
          end
        end
        resp
      end

      def update(name:)
        if (resp = useable_validation(name: name)).net_status_ok?
          mapper = index[name].mapper
          @container_controller._update(name: mapper.container_name, docker_options: @container_controller._load_docker_options(lib_mapper: mapper.lib))
          @docker_api.image_pull(mapper.container.docker.image.value)
          index_mux_containers(name: name).each do |container_name|
            @container_controller.instance_eval do
              docker_options = _load_docker_options(lib_mapper: index[container_name].lib_mapper)
              _update(name: container_name, docker_options: docker_options, with_pull: false)
            end
          end
        end
        resp
      end

      def tree(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = @config.muxs.f(name)
          { data: MapperInheritance::Mux.tree(mapper)[name] }
        else
          resp
        end
      end

      def inspect(name:, inheritance: false)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = index[name].mapper
          if inheritance
            data = separate_inheritance(mapper) do |base, inheritors|
              ([base] + inheritors).reverse.inject([]) do |total, m|
                total << { 'name' => mapper_name(m), 'options' => get_mapper_options(m, erb: true) }
              end
            end
            { data: data }
          else
            { data: { 'name' => mapper.name, 'options' => get_mapper_options(mapper, erb: true) } }
          end
        else
          resp
        end
      end

      def options(name:, inheritance: false)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = index[name].mapper
          if inheritance
            data = separate_inheritance(mapper) do |base, inheritors|
              ([base] + inheritors).reverse.inject([]) do |total, m|
                total << { mapper_name(m) => get_mapper_options_pathes(m, erb: true) }
              end
            end
            { data: data }
          else
            { data: get_mapper_options_pathes(mapper, erb: true) }
          end
        else
          resp
        end
      end

      def inheritance(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          inheritance = index[name].mapper.inheritance
          { data: inheritance.reverse.map { |m| { 'type' => mapper_type(m.parent), 'name' => mapper_name(m) } } }
        else
          resp
        end
      end

      def _reconfigure(name:)
        set_state(state: 'none', state_mapper: state(name: name))
        lib_mapper = index[name].mapper.lib

        states = {
          none: { action: :install_data, undo: :uninstall_data, next: :data_installed },
          data_installed: { action: :configure_with_apply, undo: :unconfigure_with_unapply, next: :configuration_applied },
          configuration_applied: { action: :run, undo: :stop, next: :up },
        }

        on_state(state_mapper: lib_mapper, states: states, name: name)
      end
    end
  end
end
