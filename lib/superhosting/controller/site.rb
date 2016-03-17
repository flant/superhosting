module Superhosting
  module Controller
    class Site < Base
      DOMAIN_NAME_FORMAT = /^((?!-)[A-Za-z0-9-]{3,63}(?<!-)\.)+[A-Za-z]{2,6}$/

      def initialize(**kwargs)
        super(**kwargs)
        @container_controller = self.get_controller(Container)
      end

      def site_index
        site_index = {}
        @config.containers.grep_dirs.each do |container_mapper|
          container_mapper.sites.grep_dirs.each do |site_mapper|
            names = []
            names << site_mapper.name
            site_mapper.aliases.lines {|n| names << n.strip } unless site_mapper.aliases.nil?
            raise NetStatus::Exception, {
                code: :container_site_name_conflict,
                data: { site1: site_index[site_mapper.name][:site].path, site2: site_mapper.path }
            } if site_index.key? site_mapper.name
            names.each {|n| site_index[n] = { container: container_mapper, site: site_mapper } }
          end
        end
        site_index
      end

      def add(name:, container_name:)
        if (resp = self.adding_validation(name: name)).net_status_ok? and
            (resp = @container_controller.existing_validation(name: container_name)).net_status_ok?
          container_mapper = @config.containers.f(container_name)
          container_lib_mapper = @lib.containers.f(container_name)
          container_web_mapper = PathMapper.new('/web').f(container_name)
          model = container_mapper.model(default: @config.default_model)
          model_mapper = @config.models.f(:"#{model}")
          site_mapper = ModelInheritance.new(container_mapper.sites.f(name), model_mapper).get
          site_web_mapper = container_web_mapper.f(name)
          site_lib_mapper = container_lib_mapper.web.f(name).create!
          FileUtils.chown_R container_name, container_name, container_lib_mapper.web.f(name).path

          registry_sites_mapper = container_lib_mapper.registry.sites
          site_mapper.f('config.rb', overlay: false).reverse.each do |config|
            registry_mapper = registry_sites_mapper.f(name)
            ex = ScriptExecutor::Site.new(
                container_name: container_mapper.container_name,
                container: container_mapper,
                container_lib: container_lib_mapper,
                container_web: container_web_mapper,
                site_name: site_mapper.name,
                site: site_mapper,
                site_web: site_web_mapper,
                site_lib: site_lib_mapper,
                registry_mapper: registry_mapper,
                model: model_mapper,
                config: @config, lib: @lib
            )
            ex.execute(config)
            ex.commands.each {|c| self.command c }
          end

          {}
        else
          resp
        end
      end

      def delete(name:)
        if self.existing_validation(name: name).net_status_ok?
          site_info = self.site_index[name]
          container_mapper = site_info[:container]
          model = container_mapper.model(default: @config.default_model)
          model_mapper = @config.models.f(:"#{model}")
          container_lib_mapper = @lib.containers.f(container_mapper.name)
          container_web_mapper = PathMapper.new('/web').f(container_mapper.name)
          site_mapper = ModelInheritance.new(site_info[:site], model_mapper).get
          site_lib_mapper = container_lib_mapper.web.f(name)
          site_web_mapper = container_web_mapper.f(name)

          site_mapper.delete!(full: true)
          site_lib_mapper.delete!(full: true)

          registry_sites_mapper = container_lib_mapper.registry.sites
          site_mapper.f('config.rb', overlay: false).reverse.each do |config|
            registry_mapper = registry_sites_mapper.f(name)
            ex = ScriptExecutor::Site.new(
                container_name: container_mapper.name,
                container: container_mapper,
                container_lib: container_lib_mapper,
                container_web: container_web_mapper,
                site_name: site_mapper.name,
                site: site_mapper,
                site_web: site_web_mapper,
                site_lib: site_lib_mapper,
                registry_mapper: registry_mapper,
                model: model_mapper,
                config: @config,
                lib: @lib,
                on_reconfig_only: true
            )
            ex.execute(config)
            ex.commands.each {|c| self.command c }
          end

          unless (registry_site = registry_sites_mapper.f(name)).nil?
            FileUtils.rm registry_site.lines
            registry_site.delete!(full: true)
          end

          {}
        else
          self.debug("Site '#{name}' has already been deleted")
        end
      end

      def rename(name:, new_name:)
        if (resp = self.existing_validation(name: name)).net_status_ok? and
            (resp = self.adding_validation(name: new_name)).net_status_ok?
          site_info = self.site_index[name]
          container_name = site_info[:container].name
          sites_mapper = site_info[:container].sites
          container_lib_web_mapper = @lib.containers.f(container_name).web
          site_mapper = sites_mapper.f(name)
          site_new_mapper = sites_mapper.f(new_name)
          renaming_mapper = sites_mapper.f("renaming_#{site_mapper.name}")
          site_lib_mapper = container_lib_web_mapper.f(name)
          site_lib_new_mapper = container_lib_web_mapper.f(new_name)
          renaming_lib_mapper = container_lib_web_mapper.f("renaming_#{site_lib_mapper.name}")

          self.command("cp -rp #{site_mapper.path} #{renaming_mapper.path}")
          self.command("cp -rp #{site_lib_mapper.path} #{renaming_lib_mapper.path}")

          if (resp = self.add(name: new_name, container_name: container_name)).net_status_ok?
            FileUtils.rm_rf site_new_mapper.path
            FileUtils.rm_rf site_lib_new_mapper.path
            FileUtils.mv renaming_mapper.path, site_new_mapper.path
            FileUtils.mv renaming_lib_mapper.path, site_lib_new_mapper.path
            resp = self.delete(name: name)
          end
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
        self.site_index[name].nil? ? { error: :logical_error, code: :site_does_not_exists, data: { name: name } } : {}
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :site_exists, data: { name: name} } : {}
      end
    end
  end
end