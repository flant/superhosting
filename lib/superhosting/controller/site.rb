module Superhosting
  module Controller
    class Site < Base
      DOMAIN_NAME_FORMAT = /^((?!-)[А-Яа-яA-Za-z0-9-]{3,63}(?<!-)\.)+[А-Яа-яA-Za-z]{2,6}$/

      def initialize(**kwargs)
        super(**kwargs)
        @container_controller = self.get_controller(Container)
        self.index
      end

      def list(container_name:)
        if (resp = @container_controller.available_validation(name: container_name)).net_status_ok?
          { data: self._list(container_name: container_name) }
        else
          resp
        end
      end

      def _list(container_name:)
        container_mapper = @container_controller.index[container_name][:mapper]
        sites = []
        container_mapper.sites.grep_dirs.each do |mapper|
          if (state = container_mapper.lib.sites.f(mapper.name).state).file?
            sites << { name: mapper.name, state: state.value }
          end
        end
        sites
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
        if (resp = self.existing_validation(name: name)).net_status_ok? and
            ((resp = self.adding_validation(name: new_name)).net_status_ok? or
                (is_alias = alias_existing_validation(name: name, alias_name: new_name)))
          begin
            mapper = self.index[name][:mapper]
            container_mapper = self.index[name][:container_mapper]
            actual_name = mapper.name
            renaming_mapper = mapper.etc.parent.f("renaming_#{mapper.name}")
            renaming_lib_mapper = mapper.lib.parent.f("renaming_#{actual_name}")

            mapper.aliases_mapper.remove_line!(new_name) if defined? is_alias and is_alias
            mapper.aliases_mapper.append_line!(name) if alias_name

            mapper.rename!(renaming_mapper.path)
            mapper.create!
            mapper.lib.rename!(renaming_lib_mapper.path)
            mapper.lib.create!

            self.reindex_site(name: actual_name, container_name: container_mapper.name)

            if (resp = self._reconfigure(name: new_name, container_name: container_mapper.name)).net_status_ok?
              new_site_mapper = self.index[new_name][:mapper]
              renaming_mapper.rename!(new_site_mapper.etc.path, logger: false)
              renaming_lib_mapper.rename!(new_site_mapper.lib.path, logger: false)
              mapper.aliases_mapper.rename!(new_site_mapper.aliases_mapper.path, logger: false)
              resp = self.delete(name: actual_name)
            end
          ensure
            unless resp.net_status_ok?
              renaming_mapper.delete!(logger: false)
              renaming_lib_mapper.delete!(logger: false)
              mapper.aliases_mapper.append_line!(new_name) if defined? is_alias and is_alias
              mapper.aliases_mapper.remove_line!(name) if alias_name
            end
          end
        end
        resp
      end

      def reconfigure(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          actual_name = self.index[name][:mapper].name
          self.set_state(name: actual_name, state: :data_installed)
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
            data_installed: { action: :configure_with_apply, undo: :unconfigure, next: :up },
        }

        self.on_state(state_mapper: state_mapper, states: states,
                      name: name, container_name: container_name, **kwargs)
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

      def alias_existing_validation(name:, alias_name:)
        self.index[name][:mapper].aliases.include?(alias_name)
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :site_exists, data: { name: name} } : {}
      end

      def available_validation(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          resp = (self.index[name][:container_mapper].lib.sites.state.value == 'up') ? {} : { error: :logical_error, code: :site_is_not_available, data: { name: name }  }
        end
        resp
      end

      def index
        @@index ||= self.reindex
      end

      def reindex
        @config.containers.grep_dirs.each do |container_mapper|
          container_mapper.sites.grep_dirs.each { |mapper| self.reindex_site(name: mapper.name, container_name: container_mapper.name) }
        end
        @@index ||= {}
      end


      def reindex_site(name:, container_name:)
        @@index ||= {}
        @@index[name][:aliases].each{|n| @@index.delete(n) } if @@index[name]

        container_mapper = @container_controller.index[container_name][:mapper]
        etc_mapper = container_mapper.sites.f(name)
        lib_mapper = container_mapper.lib.web.f(name)
        web_mapper = container_mapper.web.f(name)
        state_mapper = container_mapper.lib.sites.f(name).state

        if etc_mapper.nil?
          @@index.delete(name)
          return
        end

        model_name = container_mapper.f('model', default: @config.default_model)
        model_mapper = @config.models.f(model_name)
        etc_mapper = MapperInheritance::Model.new(model_mapper).set_inheritors(etc_mapper)

        mapper = CompositeMapper.new(etc_mapper: etc_mapper, lib_mapper: lib_mapper, web_mapper: web_mapper)
        etc_mapper.erb_options = { site: mapper, container: mapper }

        if @@index.key? name and @@index[name][:mapper].path != mapper.path
          raise NetStatus::Exception, { code: :container_site_name_conflict,
                                        data: { site1: @@index[name][:mapper].path, site2: mapper.path } }
        end

        ([mapper.name] + mapper.aliases).each {|name| @@index[name] = { mapper: mapper, container_mapper: container_mapper, state_mapper: state_mapper, aliases: [mapper.name] + mapper.aliases } }
      end
    end
  end
end