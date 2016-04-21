module Superhosting
  module Controller
    class Container < Base
      def list
        containers = self._list
        { data: containers }
      end

      def _list
        containers = []
        @config.containers.grep_dirs.map do |n|
          name = n.name
          containers << self._inspect(name: name) if self.index.key?(name) && self.index[name][:mapper].lib.state.file?
        end
        containers
      end

      def inspect(name:, inheritance: false, erb: false)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          if inheritance
            mapper = self.index[name][:mapper]
            data = separate_inheritance(mapper) do |mapper, inheritors|
              inheritors.inject([self._inspect(name: mapper.name, erb: erb)]) do |inheritance, m|
                inheritance << { 'type' => mapper_type(m.parent), 'name' => mapper_name(m), 'options' => get_mapper_options(m, erb: erb) }
              end
            end
            { data: data }
          else
            { data: self._inspect(name: name, erb: erb) }
          end
        else
          resp
        end
      end

      def _inspect(name:, erb: false)
        mapper = self.index[name][:mapper]
        model_name = self.index[name][:model_name]
        user_controller = self.get_controller(User)
        {
          'name' => name,
          'state' => self.state(name: name).value,
          'model' => model_name,
          'users' => user_controller.list(container_name: name).net_status_ok![:data],
          'options' => get_mapper_options(mapper, erb: erb)
        }
      end

      def inheritance(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          { data: self._inheritance(name: name) }
        else
          resp
        end
      end

      def options(name:, inheritance: false, erb: false)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          { data: self._options(name: name, inheritance: inheritance, erb: erb) }
        else
          resp
        end
      end

      def add(name:, model: nil)
        if (resp = self.not_existing_validation(name: name)).net_status_ok? &&
           (resp = self.adding_validation(name: name)).net_status_ok?
          resp = self._reconfigure(name: name, model: model)
        end
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

      def update(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok? && @docker_api.container_exists?(name)
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
        if (resp = self.available_validation(name: name)).net_status_ok? &&
           (resp = self.adding_validation(name: new_name)).net_status_ok?
          mapper = self.index[name][:mapper]
          status_name = "#{name}_to_#{new_name}"
          state_mapper = @lib.process_status.f(status_name).create!
          model = nil if (model = mapper.f('model').value).nil?

          states = {
            none: { action: :stop, undo: :run, next: :stopped },
            stopped: { action: :unconfigure_with_unapply, undo: :configure_with_apply, next: :unconfigured },
            unconfigured: { action: :copy_etc, next: :copied_etc },
            copied_etc: { action: :new_up, next: :new_upped },
            new_upped: { action: :copy_var, next: :copied_var },
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

      def reconfigure(name:, model: nil)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          state = model ? :none : :data_installed
          self.set_state(state: state, state_mapper: self.state(name: name))
          resp = self._reconfigure(name: name, model: model)
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

      def model(name:)
        self.get_controller(Model, name: name)
      end
    end
  end
end
