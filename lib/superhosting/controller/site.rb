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
        sites = []
        sites_mappers = container_name.nil? ? self.index : self.container_sites(container_name: container_name)
        sites_mappers.each do |name, _index|
          sites << self._inspect(name: name) if (state = self.state(name: name)).file?
        end

        sites
      end

      def inspect(name:, inheritance: false, erb: false)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          if inheritance
            mapper = self.index[name][:mapper]
            data = separate_inheritance(mapper) do |mapper, inheritors|
              inheritors.inject([self._inspect(name: mapper.name, erb: erb)]) do |inheritance, m|
                inheritance << { 'type' => get_mapper_type(m.parent), 'name' => get_mapper_name(m), 'options' => get_mapper_options(m, erb: erb) }
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
        actual_name = mapper.name
        container_mapper = self.index[actual_name][:container_mapper]
        alias_controller = self.get_controller(Alias, name: actual_name)
        {
            'name' => actual_name,
            'container' => container_mapper.name,
            'state' => self.state(name: actual_name).value,
            'aliases' => alias_controller._list,
            'options' => get_mapper_options(mapper, erb: erb)
        }
      end

      def inheritance(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          mapper = self.index[name][:mapper]
          { data: mapper.inheritance.map{|m| { 'type' => get_mapper_type(m.parent), 'name' => get_mapper_name(m) } } }
        else
          resp
        end
      end

      def options(name:, inheritance: false, erb: false)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          mapper = self.index[name][:mapper]
          if inheritance
            data = separate_inheritance(mapper) do |mapper, inheritors|
              ([mapper] + inheritors).inject([]) do |inheritance, m|
                type, name = get_mapper_type(m), get_mapper_name(m)
                name = type if type == 'site'
                inheritance << { "#{ "#{type}: " if type == 'mux' }#{name}" => get_mapper_options_pathes(m, erb: erb) }
              end
            end
            { data: data }
          else
            { data: get_mapper_options_pathes(mapper, erb: erb) }
          end
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