module Superhosting
  module Controller
    class Container < Base
      def list
        containers = _list
        { data: containers }
      end

      def _list
        containers = []
        index.each { |name, index_item| containers << { 'name' => name, 'state' => index_item.state_mapper.value } }
        containers
      end

      def inspect(name:, inheritance: false, erb: false)
        if (resp = existing_validation(name: name)).net_status_ok?
          { data: super }
        else
          resp
        end
      end

      def _inspect(name:, erb: false)
        index_item = index[name]
        inheritance_mapper = index_item.inheritance_mapper
        model_name = index_item.model_name
        user_controller = controller(User)
        {
          'name' => name,
          'state' => index_item.state_mapper.value,
          'model' => model_name,
          'users' => user_controller._list(container_name: name),
          'options' => get_mapper_options(inheritance_mapper, erb: erb)
        }
      end

      def inheritance(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          { data: super }
        else
          resp
        end
      end

      def options(name:, inheritance: false, erb: false)
        if (resp = existing_validation(name: name)).net_status_ok?
          { data: super }
        else
          resp
        end
      end

      def add(name:, model: nil)
        if (resp = not_existing_validation(name: name)).net_status_ok? &&
           (resp = adding_validation(name: name)).net_status_ok?
          resp = _reconfigure(name: name, model: model)
        end
        resp
      end

      def delete(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          lib_mapper = @lib.containers.f(name)

          states = {
            up: { action: :stop, undo: :run, next: :configuration_applied },
            configuration_applied: { action: :unconfigure_with_unapply, undo: :configure_with_apply, next: :mux_runned },
            mux_runned: { action: :stop_mux, undo: :run_mux, next: :databases_installed },
            databases_installed: { action: :uninstall_databases, next: :users_installed },
            users_installed: { action: :uninstall_users, next: :data_installed },
            data_installed: { action: :uninstall_data }
          }

          on_state(state_mapper: lib_mapper, states: states,
                   name: name)
        end
        resp
      end

      def update(name:)
        if (resp = existing_validation(name: name)).net_status_ok? && @docker_api.container_exists?(name)
          mapper = index[name].mapper
          _update(name: name, docker_options: _load_docker_options(lib_mapper: mapper.lib))
        end
        resp
      end

      def _update(name:, docker_options:, with_pull: true)
        command_options, image, command = docker_options
        @docker_api.image_pull(image) if with_pull
        _recreate_docker(command_options, image, command, name: name) unless @docker_api.container_image?(name, image)
      end

      def rename(name:, new_name:)
        if (resp = available_validation(name: name)).net_status_ok? &&
           (resp = adding_validation(name: new_name)).net_status_ok?
          mapper = index[name].mapper
          status_name = "#{name}_to_#{new_name}"
          state_mapper = @lib.process_status.f(status_name).create!
          model = nil if (model = mapper.f('model').value).nil?

          states = {
              none: { action: :stop, undo: :run, next: :stopped },
              stopped: { action: :unconfigure_with_unapply, undo: :configure_with_apply, next: :unconfigured },
              unconfigured: { action: :copy_etc, next: :copied_etc },
              copied_etc: { action: :new_up, next: :new_upped },
              new_upped: { action: :copy_var, next: :copied_var },
              copied_var: { action: :move_databases, next: :moved_databases },
              moved_databases: { action: :copy_users, next: :copied_users },
              copied_users: { action: :new_reconfigure, next: :new_reconfigured },
              new_reconfigured: { action: :delete }
          }

          on_state(state_mapper: state_mapper, states: states,
                   name: name, new_name: new_name, model: model)
        else
          resp
        end
      end

      def reconfigure(name:, model: nil)
        if (resp = existing_validation(name: name)).net_status_ok?
          state = model ? :none : :data_installed
          set_state(state: state, state_mapper: self.state(name: name))
          resp = _reconfigure(name: name, model: model)
        end
        resp
      end

      def _reconfigure(name:, **kwargs)
        lib_mapper = @lib.containers.f(name)

        states = {
          none: { action: :stop_old_mux, undo: :run_mux, next: :old_mux_stopped },
          old_mux_stopped: { action: :install_data, undo: :uninstall_data, next: :data_installed },
          data_installed: { action: :install_users, undo: :uninstall_users, next: :users_installed },
          users_installed: { action: :install_databases, undo: :uninstall_databases, next: :databases_installed },
          databases_installed: { action: :run_mux, undo: :stop_mux, next: :mux_runned },
          mux_runned: { action: :configure_with_apply, undo: :unconfigure_with_unapply, next: :configuration_applied },
          configuration_applied: { action: :run, undo: :stop, next: :up }
        }

        on_state(state_mapper: lib_mapper, states: states,
                 name: name, **kwargs)
      end

      def save(name:, to:)
      end

      def restore(name:, from:, mail: 'model', admin_mail: nil, model: nil)
      end

      def admin(name:)
        controller(Admin, name: name)
      end

      def model(name:)
        controller(Model, name: name)
      end
    end
  end
end
