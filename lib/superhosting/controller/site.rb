module Superhosting
  module Controller
    class Site < Base
      DOMAIN_NAME_FORMAT = /^((?!-)[А-Яа-яA-Za-z0-9-]{3,63}(?<!-)\.)+[А-Яа-яA-Za-z]{2,6}$/

      def initialize(**kwargs)
        super(**kwargs)
        @container_controller = self.get_controller(Container)
      end

      def list(container_name:)
        if (resp = @container_controller.existing_validation(name: container_name)).net_status_ok?
          container_mapper = @container_controller.index[container_name][:mapper]
          sites = []
          container_mapper.sites.grep_dirs.each do |mapper|
            sites << mapper.name
          end
          { data: sites }
        else
          resp
        end
      end

      def add(name:, container_name:)
        lib_mapper = @container_controller.index[container_name][:mapper].lib
        state_mapper = lib_mapper.web.f(name)

        states = {
            none: { action: :install_data, undo: :uninstall_data, next: :data_installed },
            data_installed: { action: :configure, undo: :unconfigured, next: :configured },
            configured: { action: :apply, undo: :unapply, next: :up }
        }

        self.on_state(state_mapper: state_mapper, states: states, name: name, container_name: container_name)
      end

      def delete(name:)
        lib_mapper = self.index[name][:container_mapper].lib
        state_mapper = lib_mapper.web.f(name)

        states = {
            up: { action: :unapply, undo: :apply, next: :configured },
            configured: { action: :unconfigure, next: :data_installed },
            data_installed: { action: :uninstall_data },
        }

        self.on_state(state_mapper: state_mapper, states: states, name: name)
      end

      def rename(name:, new_name:)
        if (resp = self.existing_validation(name: name)).net_status_ok? and
            (resp = self.adding_validation(name: new_name)).net_status_ok?
          mapper = self.index[name][:mapper]
          container_mapper = self.index[name][:container_mapper]
          sites_mapper = container_mapper.sites
          new_site_mapper = sites_mapper.f(new_name)
          renaming_mapper = sites_mapper.f("renaming_#{mapper.name}")
          new_site_lib_mapper = container_mapper.lib.web.f(new_name)
          renaming_lib_mapper = container_mapper.lib.web.f("renaming_#{name}")

          self.command!("cp -rp #{mapper.path} #{renaming_mapper.path}")
          self.command!("cp -rp #{mapper.lib.path} #{renaming_lib_mapper.path}")

          if (resp = self.add(name: new_name, container_name: container_mapper.name)).net_status_ok?
            new_site_mapper.delete!
            new_site_lib_mapper.delete!
            FileUtils.mv renaming_mapper.path, new_site_mapper.path
            FileUtils.mv renaming_lib_mapper.path, new_site_lib_mapper.path
            resp = self.delete(name: name)
          end
        end
        resp
      end

      def reconfig(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          self._reconfig(name: name)
        end
        resp
      end

      def alias(name:)
        self.get_controller(Alias, name: name)
      end

      def adding_validation(name:)
        return { error: :input_error, code: :invalid_site_name, data: { name: name, regex: DOMAIN_NAME_FORMAT } } if name !~ DOMAIN_NAME_FORMAT
        self.not_existing_validation(name: name)
      end

      def existing_validation(name:)
        self.index[name].nil? ? { error: :logical_error, code: :site_does_not_exists, data: { name: name } } : {}
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :site_exists, data: { name: name} } : {}
      end

      def index
        def generate
          @config.containers.grep_dirs.each do |container_mapper|
            container_mapper.sites.grep_dirs.each { |mapper| self.reindex_site(name: mapper.name, container_name: container_mapper.name) }
          end
          @index ||= {}
        end

        @index || generate
      end

      def reindex_site(name:, container_name:)
        @index ||= {}

        container_mapper = @container_controller.index[container_name][:mapper]
        etc_mapper = container_mapper.sites.f(name)
        lib_mapper = container_mapper.lib.web.f(name)
        web_mapper = container_mapper.web.f(name)

        if etc_mapper.nil?
          @index.delete(name)
          return
        end

        model_name = container_mapper.f('model', default: @config.default_model)
        model_mapper = @config.models.f(model_name)
        etc_mapper = MapperInheritance::Model.new(etc_mapper, model_mapper).get

        mapper = ScriptExecutor::ConfigMapper::Site.new(etc_mapper: etc_mapper,
                                                        lib_mapper: lib_mapper,
                                                        web_mapper: web_mapper)
        etc_mapper.erb_options = { site: mapper, container: mapper }

        if @index.key? name and @index[name][:mapper].path != mapper.path
          raise NetStatus::Exception, { code: :container_site_name_conflict,
                                        data: { site1: @index[name][:mapper].path, site2: mapper.path } }
        end

        ([mapper.name] + mapper.aliases).each {|name| @index[name] = { mapper: mapper, container_mapper: container_mapper } }
      end
    end
  end
end