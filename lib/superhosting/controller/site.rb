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

      def rename(name:, new_name:, alias_name: false)
        if (resp = self.available_validation(name: name)).net_status_ok? and
          ((resp = self.adding_validation(name: new_name)).net_status_ok? or
              (is_alias = alias_existing_validation(name: name, alias_name: new_name)))

          mapper = self.index[name][:mapper]
          container_mapper = self.index[name][:container_mapper]
          actual_name = mapper.name

          mapper.aliases_mapper.remove_line!(new_name) if defined? is_alias and is_alias
          self.reindex_container_sites(container_name: container_mapper.name)

          begin
            self.unconfigure_with_unapply(name: actual_name).net_status_ok!
            if (resp = self._reconfigure(name: new_name, container_name: container_mapper.name)).net_status_ok?
              new_mapper = self.index[new_name][:mapper]
              mapper.etc.rename!(new_mapper.etc.path)
              mapper.lib.rename!(new_mapper.lib.path)
              mapper.aliases_mapper.rename!(new_mapper.aliases_mapper.path)

              self.reconfigure(name: new_name).net_status_ok!
              self.delete(name: actual_name).net_status_ok!

              new_mapper.aliases_mapper.append_line!(actual_name) if alias_name
              self.reindex_container_sites(container_name: container_mapper.name)
            end
          rescue Exception => e
            resp = e.net_status
            raise
          ensure
            unless resp.net_status_ok?
              unless new_mapper.nil?
                mapper.aliases_mapper.append_line!(new_name) if defined? is_alias and is_alias
                mapper.aliases_mapper.remove_line!(name) if alias_name

                new_mapper.etc.rename!(mapper.path)
                new_mapper.lib.rename!(mapper.lib.path)

                self.reconfigure(name: name)
              end

              self.delete(name: new_name)
            end
          end
        end
        resp
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