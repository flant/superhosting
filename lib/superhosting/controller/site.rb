module Superhosting
  module Controller
    class Site < Base
      def list(container_name: nil)
        if container_name.nil? or (resp = @container_controller.available_validation(name: container_name)).net_status_ok?
          { data: self._list(container_name: container_name) }
        else
          resp
        end
      end

      def _list(container_name: nil)
        def data(name)
          mapper = self.index[name][:mapper]
          docker_options = mapper.docker.grep_files.map {|f| [f.name, f.value] }.to_h
          configs = mapper.f('config.rb', overlay: false).reverse.map {|f| f.value }
          { docker: docker_options, configs: configs, aliases: self.index[name][:aliases]-[name] }
        end

        sites = {}
        if container_name
          container_mapper = @container_controller.index[container_name][:mapper]
          container_mapper.sites.grep_dirs.each do |mapper|
            name = mapper.name
            if (state = container_mapper.lib.sites.f(name).state).file?
              sites[name] = { state: state.value, container: container_name }.merge(data(name))
            end
          end
        else
          self.index.values.each do |index|
            name = index[:mapper].name
            if (state = index[:state_mapper]).file?
              sites[name] = { state: state.value, container: index[:container_mapper].name }.merge(data(name))
            end
          end
        end

        sites
      end

      def inspect(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          actual_name = self.index[name][:mapper].name
          container_mapper = self.index[name][:container_mapper]
          { data: self._list(container_name: container_mapper.name)[actual_name] }
        else
          resp
        end
      end

      def add(name:, container_name:)
        if (resp = @container_controller.available_validation(name: container_name)).net_status_ok? and
            (resp = self.adding_validation(name: name)).net_status_ok?
          resp = self._reconfigure(name: name, container_name: container_name)
        end
        resp
      end

      def name(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          { data: self.index[name][:mapper].name }
        else
          resp
        end
      end

      def container(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          { data: self.index[name][:container_mapper].name }
        else
          resp
        end
      end

      def delete(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          lib_sites_mapper = self.index[name][:container_mapper].lib.sites
          actual_name = self.index[name][:mapper].name
          state_mapper = lib_sites_mapper.f(actual_name)

          states = {
              up: { action: :unapply, undo: :apply, next: :configured },
              configured: { action: :unconfigure, next: :data_installed },
              data_installed: { action: :uninstall_data },
          }

          self.on_state(state_mapper: state_mapper, states: states, name: actual_name)
        end
        resp
      end

      def rename(name:, new_name:, keep_name_as_alias: false)
        if (resp = self.available_validation(name: name)).net_status_ok? and
            ((resp = self.adding_validation(name: new_name)).net_status_ok? or
                (is_alias = alias_existing_validation(name: name, alias_name: new_name)))
          mapper = self.index[name][:mapper]
          status_name = "#{name}_to_#{new_name}"
          state_mapper = @lib.process_status.f(status_name).create!
          actual_name = mapper.name
          container_name = self.index[name][:container_mapper].name

          states = {
              none: { action: :unconfigure_with_unapply, undo: :configure_with_apply, next: :unconfigured },
              unconfigured: { action: :new_up, next: :new_upped },
              new_upped: { action: :copy, next: :copied },
              copied: { action: :new_reconfigure, next: :new_reconfigured },
              new_reconfigured: { action: :delete, next: :deleted },
              deleted: { action: :keep_name_as_alias }
          }

          self.on_state(state_mapper: state_mapper, states: states,
                        name: actual_name, new_name: new_name, container_name: container_name,
                        is_alias: is_alias, keep_name_as_alias: keep_name_as_alias)
        else
          resp
        end
      end

      def reconfigure(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          actual_name = self.index[name][:mapper].name
          self.set_state(state: :data_installed, state_mapper: self.state(name: actual_name))
          self._reconfigure(name: actual_name)
        end
        resp
      end

      def _reconfigure(name:, **kwargs)
        lib_sites_mapper = if (container_name = kwargs[:container_name])
          @container_controller.index[container_name][:mapper].lib.sites
        else
          self.index[name][:container_mapper].lib.sites
        end
        state_mapper = lib_sites_mapper.f(name)

        states = {
            none: { action: :install_data, undo: :uninstall_data, next: :data_installed },
            data_installed: { action: :configure_with_apply, undo: :unconfigure_with_unapply, next: :up },
        }

        self.on_state(state_mapper: state_mapper, states: states,
                      name: name, container_name: container_name, **kwargs)
      end

      def alias(name:)
        self.get_controller(Alias, name: name)
      end
    end
  end
end