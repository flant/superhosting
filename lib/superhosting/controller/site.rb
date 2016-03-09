module Superhosting
  module Controller
    class Site < Base
      attr_reader :site_index

      DOMAIN_NAME_FORMAT = /^((?!-)[A-Za-z0-9-]{1,63}(?<!-)\.)+[A-Za-z]{2,6}$/

      def initialize(**kwargs)
        super(**kwargs)
        @container_controller = self.get_controller(Container)
      end

      def site_index
        def generate
          @site_index = {}
          @config.containers.grep_dirs.each do |container_dir|
            container_dir.sites.grep_dirs.each do |site_dir|
              names = []
              names << site_dir.name
              site_dir.aliases.lines {|n| names << n.strip } unless site_dir.aliases.nil?
              raise NetStatus::Exception, { error: :error, message: "Conflict between containers sites: '#{@site_index[site_dir.name][:site].path}' and '#{site_dir.path}'" } if @site_index.key? site_dir.name
              names.each {|n| @site_index[n] = { container: container_dir, site: site_dir } }
            end
          end
          @site_index
        end

        @site_index ||= self.generate
      end

      def add(name:, container_name:)
        if (resp = self.adding_validation(name: name)).net_status_ok? and
            (resp = @container_controller.existing_validation(name: container_name)).net_status_ok?
          container_mapper = @config.containers.f(container_name)
          container_lib_mapper = @lib.containers.f(container_name)
          site_mapper = container_mapper.sites.f(name)
          model = container_mapper.model(default: @config.default_model).value
          model_mapper = @config.models.f(:"#{model}")

          site_mapper.create!
          container_lib_mapper.web.f(name).create!

          registry_sites_mapper = container_lib_mapper.registry.sites
          unless model_mapper.f('site.rb').nil?
            registry_path = registry_sites_mapper.f(name).path
            registry_sites_mapper.create!
            ex = ScriptExecutor::Site.new(
                site: site_mapper, site_name: name,
                container: container_mapper, container_name: name, container_lib: container_lib_mapper, registry_path: registry_path,
                model: model_mapper, config: @config, lib: @lib
            )
            ex.execute(model_mapper.f('site.rb'))
            ex.commands.each {|c| self.command c }
          end

          {}
        else
          resp
        end
      end

      def delete(name:)
        if self.existing_validation(name: name).net_status_ok?
          site = self.site_index[name]
          container_sites = site[:container].sites
          container_mapper = site[:container]
          container_lib_mapper = @lib.containers.f(container_mapper.name)
          lib_web_site_mapper = container_lib_mapper.web.f(name)
          model = container_mapper.model(default: @config.default_model).value
          model_mapper = @config.models.f(:"#{model}")

          site[:site].delete!(full: true)
          container_sites.delete! if container_sites.empty?
          lib_web_site_mapper.delete! if lib_web_site_mapper.nil?

          registry_sites_mapper = container_lib_mapper.registry.sites

          unless model_mapper.f('site.rb').nil?
            registry_path = registry_sites_mapper.f(name).path
            registry_sites_mapper.create!
            ex = ScriptExecutor::Site.new(
                site: site[:site], site_name: name,
                container: container_mapper, container_name: name, container_lib: container_lib_mapper,
                registry_path: registry_path, on_reconfig_only: true,
                model: model_mapper, config: @config, lib: @lib
            )
            ex.execute(model_mapper.f('site.rb'))
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
          site = self.site_index[name]
          container_mapper = @config.containers.f(site[:container].name)
          container_lib_mapper = @lib.containers.f(container_mapper.name)

          FileUtils.mv site[:container].sites.f(name).path, site[:container].sites.f(new_name).path

          unless (registry_sites_mapper = container_lib_mapper.registry.sites).nil?
            FileUtils.mv registry_sites_mapper.f(name).path, registry_sites_mapper.f(new_name).path unless registry_sites_mapper.f(name).nil?
          end

          {}
        else
          resp
        end
      end

      def alias(name:)
        self.get_controller(Alias, name: name)
      end

      def adding_validation(name:)
        return { error: :input_error, message: "Invalid site name '#{name}' only '#{DOMAIN_NAME_FORMAT}'" } if name !~ DOMAIN_NAME_FORMAT
        self.not_existing_validation(name: name)
      end

      def existing_validation(name:)
        self.site_index[name].nil? ? { error: :logical_error, message: "Site '#{name}' doesn't exists." } : {}
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, message: "Site '#{name}' already exists." } : {}
      end
    end
  end
end