module Superhosting
  module Controller
    class Site < Base
      def list(container_name: nil)
        if container_name.nil? || (resp = @container_controller.available_validation(name: container_name)).net_status_ok?
          { data: _list(container_name: container_name) }
        else
          resp
        end
      end

      def _list(container_name: nil)
        sites = []
        sites_hash = container_name.nil? ? index : container_sites(container_name: container_name)
        sites_hash.each do |name, _index|
          sites << _inspect(name: name) if state(name: name).file?
        end

        sites
      end

      def inspect(name:, inheritance: false, erb: false)
        if (resp = existing_validation(name: name)).net_status_ok?
          { data: super }
        else
          resp
        end
      end

      def _inspect(name:, erb: false)
        mapper = index[name][:mapper]
        actual_name = mapper.name
        container_mapper = index[actual_name][:container_mapper]
        alias_controller = get_controller(Alias, name: actual_name)
        {
          'name' => actual_name,
          'container' => container_mapper.name,
          'state' => state(name: actual_name).value,
          'aliases' => alias_controller._list,
          'options' => get_mapper_options(mapper, erb: erb)
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

      def add(name:, container_name:)
        if (resp = @container_controller.available_validation(name: container_name)).net_status_ok? &&
           (resp = adding_validation(name: name)).net_status_ok?
          resp = _reconfigure(name: name, container_name: container_name)
        end
        resp
      end

      def name(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          { data: index[name][:mapper].name }
        else
          resp
        end
      end

      def container(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          { data: index[name][:container_mapper].name }
        else
          resp
        end
      end

      def delete(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          lib_sites_mapper = index[name][:container_mapper].lib.sites
          actual_name = index[name][:mapper].name
          state_mapper = lib_sites_mapper.f(actual_name)

          states = {
            up: { action: :unapply, undo: :apply, next: :configured },
            configured: { action: :unconfigure, next: :data_installed },
            data_installed: { action: :uninstall_data }
          }

          on_state(state_mapper: state_mapper, states: states, name: actual_name)
        end
        resp
      end

      def rename(name:, new_name:, keep_name_as_alias: false)
        if (resp = available_validation(name: name)).net_status_ok? &&
           ((resp = adding_validation(name: new_name)).net_status_ok? ||
             (is_alias = alias_existing_validation(name: name, alias_name: new_name)))
          mapper = index[name][:mapper]
          status_name = "#{name}_to_#{new_name}"
          state_mapper = @lib.process_status.f(status_name).create!
          actual_name = mapper.name
          container_name = index[name][:container_mapper].name

          states = {
            none: { action: :unconfigure_with_unapply, undo: :configure_with_apply, next: :unconfigured },
            unconfigured: { action: :new_up, next: :new_upped },
            new_upped: { action: :copy, next: :copied },
            copied: { action: :new_reconfigure, next: :new_reconfigured },
            new_reconfigured: { action: :delete, next: :deleted },
            deleted: { action: :keep_name_as_alias }
          }

          on_state(state_mapper: state_mapper, states: states,
                   name: actual_name, new_name: new_name, container_name: container_name,
                   is_alias: is_alias, keep_name_as_alias: keep_name_as_alias)
        else
          resp
        end
      end

      def reconfigure(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          actual_name = index[name][:mapper].name
          set_state(state: :data_installed, state_mapper: state(name: actual_name))
          _reconfigure(name: actual_name)
        end
        resp
      end

      def _reconfigure(name:, **kwargs)
        lib_sites_mapper = if (container_name = kwargs[:container_name])
                             @container_controller.index[container_name][:mapper].lib.sites
                           else
                             index[name][:container_mapper].lib.sites
                           end
        state_mapper = lib_sites_mapper.f(name)

        states = {
          none: { action: :install_data, undo: :uninstall_data, next: :data_installed },
          data_installed: { action: :configure_with_apply, undo: :unconfigure_with_unapply, next: :up }
        }

        on_state(state_mapper: state_mapper, states: states,
                 name: name, container_name: container_name, **kwargs)
      end

      def alias(name:)
        get_controller(Alias, name: name)
      end
    end
  end
end
