module Superhosting
  module Controller
    class Site
      class << self; attr_accessor :index end

      def initialize(**kwargs)
        super(**kwargs)
        @container_controller = get_controller(Container)
        index
      end

      def index
        self.class.index ||= reindex
      end

      def reindex
        @config.containers.grep_dirs.each do |container_mapper|
          reindex_container_sites(container_name: container_mapper.name)
        end
        self.class.index ||= {}
      end

      def reindex_container_sites(container_name:)
        @config.containers.f(container_name).sites.grep_dirs.each do |site_mapper|
          reindex_site(name: site_mapper.name, container_name: container_name)
        end
      end

      def alias?(name:)
        index[name][:mapper].name != name
      end

      def container_sites(container_name:)
        index.select { |k, v| v[:container_mapper].name == container_name && !alias?(name: k) }
      end

      def reindex_site(name:, container_name:)
        self.class.index ||= {}
        self.class.index[name][:names].each { |n| self.class.index.delete(n) } if self.class.index[name]

        container_mapper = @container_controller.index[container_name][:mapper]
        model_name = @container_controller.index[container_name][:model_name]
        etc_mapper = container_mapper.sites.f(name)
        lib_mapper = container_mapper.lib.web.f(name)
        web_mapper = container_mapper.web.f(name)
        state_mapper = container_mapper.lib.sites.f(name).state

        if etc_mapper.nil?
          self.class.index.delete(name)
          return
        end

        model_mapper = @config.models.f(model_name)
        etc_mapper = MapperInheritance::Model.new(model_mapper).inheritors_mapper(etc_mapper)

        mapper = CompositeMapper.new(etc_mapper: etc_mapper, lib_mapper: lib_mapper, web_mapper: web_mapper)
        etc_mapper.erb_options = { site: mapper, container: mapper, etc: @config, lib: @lib }

        if self.class.index.key?(name) && self.class.index[name][:mapper].path != mapper.path
          raise NetStatus::Exception, code: :container_site_name_conflict,
                                      data: { site1: self.class.index[name][:mapper].path, site2: mapper.path }
        end

        names = ([mapper.name] + mapper.aliases)
        names.each { |n| self.class.index[n] = { mapper: mapper, container_mapper: container_mapper, state_mapper: state_mapper, names: names } }
      end
    end
  end
end
