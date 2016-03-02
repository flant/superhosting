module Superhosting
  module Controller
    class Site < Base
      attr_reader :site_index

      DOMAIN_NAME_FORMAT = /^((?!-)[A-Za-z0-9-]{1,63}(?<!-)\.)+[A-Za-z]{2,6}$/

      def site_index
        def generate
          @site_index = {}
          @config.containers._grep_dirs.each do |c|
            c.sites._grep_dirs.each do |s|
              names = []
              names << s._name
              s.aliases.lines {|n| names << n.strip } unless s.aliases.nil?
              raise NetStatus::Exception.new(error: :error, message: "Conflict between container_sites: '#{@site_index[s._name][:site]._path}' and '#{s._path}'") if @site_index.key? s._name
              names.each {|n| @site_index[n] = { container: c, site: s } }
            end
          end
          @site_index
        end

        @site_index ||= self.generate
      end

      def add(name:, container_name:)
        return { error: :input_error, message: "Invalid site name '#{name}' only '#{DOMAIN_NAME_FORMAT}'" } if name !~ DOMAIN_NAME_FORMAT
        return { error: :logical_error, message: 'Site already exists.' } if self.site_index.include? name
        return { error: :logical_error, message: "Container '#{container_name}' doesn\'t exists." } if (config_path_mapper = @config.containers.f(container_name)).nil?

        site_mapper = config_path_mapper.sites.f(name)
        FileUtils.mkdir_p site_mapper._path

        lib_path_mapper = PathMapper.new("#{@lib_path}/containers/#{container_name}")
        model = config_path_mapper.model(default: @config.default_model)
        model_mapper = @config.models.f(:"#{model}")

        lib_sites_path = lib_path_mapper.registry.sites
        unless model_mapper.f('site.rb').nil?
          registry_path = lib_sites_path.f(name)._path
          FileUtils.mkdir_p lib_sites_path._path
          ex = ScriptExecutor::Site.new(
              site: site_mapper, site_name: name,
              container: config_path_mapper, container_name: name, container_lib: lib_path_mapper, registry_path: registry_path,
              model: model_mapper, config: @config, lib: @lib
          )
          ex.execute(model_mapper.f('site.rb'))
          ex.commands.each {|c| self.command c }
        end

        {}
      end

      def delete(name:)
        if site = self.site_index[name]
          FileUtils.rm_rf site[:site]._path
          container_sites = site[:container].sites
          FileUtils.rm_rf container_sites._path if container_sites.nil?

          config_path_mapper = site[:container]
          lib_path_mapper = PathMapper.new("#{@lib_path}/containers/#{config_path_mapper._name}")
          model = config_path_mapper.model(default: @config.default_model)
          model_mapper = @config.models.f(:"#{model}")

          lib_sites_path = lib_path_mapper.registry.sites

          unless (registry_site = lib_sites_path.f(name)).nil?
            FileUtils.rm registry_site.lines
            FileUtils.rm registry_site._path
          end

          unless model_mapper.f('site.rb').nil?
            registry_path = lib_sites_path.f(name)._path
            FileUtils.mkdir_p lib_sites_path._path
            ex = ScriptExecutor::Site.new(
                site: site[:site], site_name: name,
                container: config_path_mapper, container_name: name, container_lib: lib_path_mapper,
                registry_path: registry_path, on_reconfig_only: true,
                model: model_mapper, config: @config, lib: @lib
            )
            ex.execute(model_mapper.f('site.rb'))
            ex.commands.each {|c| self.command c }
          end

          {}
        end
      end

      def rename(name:, new_name:)
        return { error: :logical_error, message: "Site '#{name}' doesn't exists." } unless site = self.site_index[name]
        return { error: :logical_error, message: "Site '#{new_name}' already exists." } if self.site_index[new_name]

        FileUtils.mv site[:container].sites.f(name)._path, site[:container].sites.f(new_name)._path

        lib_path_mapper = PathMapper.new("#{@lib_path}/containers/#{site[:container]._name}")
        unless (lib_sites_path = lib_path_mapper.registry.sites).nil?
          FileUtils.mv lib_sites_path.f(name), lib_sites_path.f(new_name)
        end
      end

      def alias(name:, logger: @logger)
        Alias.new(name: name, logger: logger)
      end
    end
  end
end