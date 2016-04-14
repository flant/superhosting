module Superhosting
  module Controller
    class Container < Base
      def list
        containers = self._list
        { data: containers }
      end

      def _list
        def data(name)
          mapper = self.index[name][:mapper]
          docker_options = mapper.docker.grep_files.map {|f| [f.name, f.value] }.to_h
          configs = mapper.f('config.rb', overlay: false).reverse.map {|f| f.value }
          { docker: docker_options, configs: configs }
        end

        containers = {}
        @config.containers.grep_dirs.map do |n|
          name = n.name
          user_controller = self.get_controller(User)
          containers[name] = {
              state: self.state(name: name).value,
              users: user_controller._list(container_name: name),
              admins: self.admin(name: name)._list
          }.merge(data(name)) if self.index.key? name and self.index[name][:mapper].lib.state.file?
        end
        containers
      end

      def inspect(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          { data: self._list[name] }
        else
          resp
        end
      end

      def add(name:, mail: 'model', admin_mail: nil, model: nil)
        resp = self._reconfigure(name: name, mail: mail, admin_mail: admin_mail, model: model) if (resp = self.not_existing_validation(name: name)).net_status_ok?
        resp
      end

      def delete(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          lib_mapper = @lib.containers.f(name)

          states = {
              up: { action: :stop, undo: :run, next: :configuration_applied },
              configuration_applied: { action: :unconfigure_with_unapply, undo: :configure_with_apply, next: :mux_runned },
              mux_runned: { action: :stop_mux, undo: :run_mux, next: :users_installed },
              users_installed: { action: :uninstall_users, next: :data_installed },
              data_installed: { action: :uninstall_data }
          }

          self.on_state(state_mapper: lib_mapper, states: states,
                        name: name)
        end
        resp
      end

      def change(name:, mail: 'model', admin_mail: nil, model: nil)

      end

      def update(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok? and @docker_api.container_exists?(name)
          mapper = self.index[name][:mapper]
          docker_options = mapper.lib.docker_options.value
          self._update(name: name, docker_options: Marshal.load(docker_options))
        end
        resp
      end

      def _update(name:, docker_options:, with_pull: true)
        command_options, image, command = docker_options
        @docker_api.image_pull(image) if with_pull
        self._recreate_docker(command_options, image, command, name: name) unless @docker_api.container_image?(name, image)
      end

      def rename(name:, new_name:)
        if (resp = self.available_validation(name: name)).net_status_ok? and
            (resp = self.adding_validation(name: new_name)).net_status_ok?
          mapper = self.index[name][:mapper]
          status_name = "#{name}_to_#{new_name}"
          state_mapper = @lib.process_status.f(status_name).create!
          model = nil if (model = mapper.f('model').value).nil? # TODO: mail:, admin_mail:

          states = {
              none: { action: :stop, undo: :run, next: :stopped },
              stopped: { action: :unconfigure_with_unapply, undo: :configure_with_apply, next: :unconfigured },
              unconfigured: { action: :copy_etc, next: :copied_etc },
              copied_etc: { action: :new_run, next: :new_runned },
              new_runned: { action: :copy_var, next: :copied_var },
              copied_var: { action: :copy_users, next: :copied_users },
              copied_users: { action: :new_reconfigure, next: :new_reconfigured },
              new_reconfigured: { action: :delete }
          }

          self.on_state(state_mapper: state_mapper, states: states,
                        name: name, new_name: new_name, model: model)
        else
          resp
        end
      end

      def reconfigure(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          self.set_state(state: :data_installed, state_mapper: self.state(name: name))
          resp = self._reconfigure(name: name)
        end
        resp
      end

      def _reconfigure(name:, **kwargs)
        lib_mapper = @lib.containers.f(name)

        states = {
            none: { action: :install_data, undo: :uninstall_data, next: :data_installed },
            data_installed: { action: :install_users, undo: :uninstall_users, next: :users_installed },
            users_installed: { action: :run_mux, undo: :stop_mux, next: :mux_runned },
            mux_runned: { action: :configure_with_apply, undo: :unconfigure_with_unapply, next: :configuration_applied },
            configuration_applied: { action: :run, undo: :stop, next: :up }
        }

        self.on_state(state_mapper: lib_mapper, states: states,
                      name: name, **kwargs)
      end

      def save(name:, to:)

      end

      def restore(name:, from:, mail: 'model', admin_mail: nil, model: nil)

      end

      def admin(name:)
        self.get_controller(Admin, name: name)
      end
    end
  end
end
