module Superhosting
  module Controller
    class Container < Base
      CONTAINER_NAME_FORMAT = /^[a-zA-Z0-9][a-zA-Z0-9_.-]+$/

      def initialize(**kwargs)
        super
        self.index
      end

      def list
        # TODO
        # docker = @docker_api.container_list.map {|c| c['Names'].first.slice(1..-1) }.to_set
        # sx = @config.containers.grep_dirs.map {|n| n.name }.compact.to_set
        # containers = (docker & sx)

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
          containers[name] = {
              state: self.state(name: name).value
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
          image = mapper.lib.image.value
          self._recreate_docker(name: name) unless @docker_api.container_image?(name, image)
        end
        resp
      end

      def rename(name:, new_name:)
        if (resp = self.available_validation(name: name)).net_status_ok? and
            (resp = self.adding_validation(name: new_name)).net_status_ok?

          mapper = self.index[name][:mapper]
          new_etc_mapper = mapper.etc.parent.f(new_name)
          model = nil if (model = mapper.f('model').value).nil? # TODO: mail:, admin_mail:

          with_logger(logger: false) do
            mapper.rename!(new_etc_mapper.path)
            mapper.create!

            begin
              if (resp = self._reconfigure(name: new_name, model: model)).net_status_ok?
                new_mapper = self.index[new_name][:mapper]
                mapper.lib.web.rename!(new_mapper.lib.web.path)
                mapper.lib.sites.rename!(new_mapper.lib.sites.path)
                mapper.lib.registry.sites.rename!(new_mapper.lib.registry.sites.path)

                site_controller = self.get_controller(Site)
                site_controller.reindex_container_sites(container_name: new_name)
                site_controller.reindex_container_sites(container_name: name)

                self.reconfigure(name: new_name).net_status_ok!
                self.delete(name: name).net_status_ok!
              end
            rescue Exception => e
              resp = e.net_status
              raise
            ensure
              unless resp.net_status_ok?
                unless new_mapper.nil?
                  new_mapper.lib.web.rename!(mapper.lib.web.path)
                  new_mapper.lib.sites.rename!(mapper.lib.sites.path)
                  new_etc_mapper.rename!(mapper.path)
                  self.reconfigure(name: name)
                end
                self.delete(name: new_name)
              end
            end
          end
        end
        resp
      end

      def reconfigure(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          self.set_state(name: name, state: :data_installed)
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

      def base_validation(name:)
        @docker_api.container_rm_inactive!(name)
        (name !~ CONTAINER_NAME_FORMAT) ? { error: :input_error, code: :invalid_container_name, data: { name: name, regex: CONTAINER_NAME_FORMAT } } : {}
      end

      def adding_validation(name:)
        if (resp = self.base_validation(name: name)).net_status_ok?
          resp = self.not_running_validation(name: name)
        end
        resp
      end

      def running_validation(name:)
        @docker_api.container_running?(name) ? {}: { error: :logical_error, code: :container_is_not_running, data: { name: name } }
      end

      def not_running_validation(name:)
        @docker_api.container_not_running?(name) ? {} : { error: :logical_error, code: :container_is_running, data: { name: name } }
      end

      def existing_validation(name:)
        self.index.include?(name) ? {} : { error: :logical_error, code: :container_does_not_exists, data: { name: name }  }
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :container_exists, data: { name: name }  } : {}
      end

      def available_validation(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          resp = (self.index[name][:mapper].lib.state.value == 'up') ? {} : { error: :logical_error, code: :container_is_not_available, data: { name: name }  }
        end
        resp
      end

      def index
        @@index ||= self.reindex
      end

      def reindex
        @config.containers.grep_dirs.each {|mapper| self.reindex_container(name: mapper.name) }
        @@index ||= {}
      end

      def reindex_container(name:)
        @@index ||= {}
        etc_mapper = @config.containers.f(name)
        web_mapper = PathMapper.new('/web').f(name)
        lib_mapper = @lib.containers.f(name)
        state_mapper = lib_mapper.state

        if etc_mapper.nil?
          @@index.delete(name)
          return
        end

        model_name = etc_mapper.f('model', default: @config.default_model)
        model_mapper = @config.models.f(model_name)
        etc_mapper = MapperInheritance::Model.new(model_mapper).set_inheritors(etc_mapper)

        mapper = CompositeMapper.new(etc_mapper: etc_mapper, lib_mapper: lib_mapper, web_mapper: web_mapper)

        etc_mapper.erb_options = { container: mapper }
        mux_mapper = if (mux_file_mapper = etc_mapper.mux).file?
          MapperInheritance::Mux.new(@config.muxs.f(mux_file_mapper)).set_inheritors
        end

        @@index[name] = { mapper: mapper, mux_mapper: mux_mapper, state_mapper: state_mapper }
      end
    end
  end
end
