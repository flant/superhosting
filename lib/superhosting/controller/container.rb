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

        containers = @config.containers.grep_dirs.map do |n|
          n.name if self.index.key? n.name and self.index[n.name][:mapper].lib.state.file?
        end.compact
        { data: containers }
      end

      def add(name:, mail: 'model', admin_mail: nil, model: nil)
        lib_mapper = @lib.containers.f(name)

        states = {
            none: { action: :install_data, undo: :uninstall_data, next: :data_installed },
            data_installed: { action: :install_users, undo: :uninstall_users, next: :users_installed },
            users_installed: { action: :configure, undo: :unconfigure, next: :configured },
            configured: { action: :apply, next: :configuration_applied },
            configuration_applied: { action: :run, undo: :stop, next: :up }
        }

        self.on_state(state_mapper: lib_mapper, states: states,
                      name: name, mail: mail, admin_mail: admin_mail, model: model)
      end

      def delete(name:)
        if self.existing_validation(name: name).net_status_ok?
          lib_mapper = @lib.containers.f(name)

          states = {
              up: { action: :stop, undo: :run, next: :configured },
              configured: { action: :unconfigure, undo: :configure, next: :configuration_applied },
              configuration_applied: { action: :unapply, next: :users_installed },
              users_installed: { action: :uninstall_users, next: :data_installed },
              data_installed: { action: :uninstall_data }
          }

          self.on_state(state_mapper: lib_mapper, states: states,
                        name: name)
        else
          self.debug('Container has already deleted.')
        end

      end

      def change(name:, mail: 'model', admin_mail: nil, model: nil)

      end

      def update(name:)

      end

      def reconfig(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok? and (resp = self.running_validation(name: name)).net_status_ok?
          self._reconfig(name: name)
        end
        resp
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

        if etc_mapper.nil?
          @@index.delete(name)
          return
        end

        model_name = etc_mapper.f('model', default: @config.default_model)
        model_mapper = @config.models.f(model_name)
        etc_mapper = MapperInheritance::Model.new(etc_mapper, model_mapper).get

        mapper = CompositeMapper.new(etc_mapper: etc_mapper, lib_mapper: lib_mapper, web_mapper: web_mapper)

        etc_mapper.erb_options = { container: mapper }
        mux_mapper = if (mux_file_mapper = etc_mapper.mux).file?
          MapperInheritance::Mux.new(@config.muxs.f(mux_file_mapper)).get
        end

        @@index[name] = {
            mapper: mapper,
            mux_mapper: mux_mapper,
        }
      end
    end
  end
end
