module Superhosting
  module Controller
    class Site
      class << self; attr_accessor :index end

      def initialize(**kwargs)
        super(**kwargs)
        @container_controller = controller(Container)
        index
      end

      class IndexItem
        attr_accessor :name, :container_name, :controller

        def initialize(name:, container_name:, controller:)
          self.name = name
          self.container_name = container_name
          self.controller = controller
        end

        def container_item
          @container_item ||= controller.controller(Container).index[container_name]
        end

        def container_mapper
          container_item.mapper
        end

        def etc_mapper
          @etc_mapper ||= container_item.etc_mapper.sites.f(name)
        end

        def lib_mapper
          container_item.lib_mapper.web.f(name)
        end

        def web_mapper
          container_item.web_mapper.f(name)
        end

        def state_mapper
          container_item.lib_mapper.sites.f(name).state
        end

        def mapper
          @mapper ||= begin
            mapper = CompositeMapper.new(etc_mapper: etc_mapper, lib_mapper: lib_mapper, web_mapper: web_mapper)
            mapper.erb_options = { site: mapper, container: mapper, etc: controller.config, lib: controller.lib }
            mapper
          end
        end

        def inheritance_mapper
          @inheritance_mapper ||= begin
            model_mapper = controller.config.models.f(container_item.model_name)
            mapper.etc_mapper = MapperInheritance::Model.set_inheritance(model_mapper, etc_mapper)
            mapper
          end
        end

        def aliases_mapper
          lib_mapper.parent.parent.sites.f(name).aliases
        end

        def names
          @names ||= [name] + aliases_mapper.lines
        end
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
        index[name].name != name
      end

      def container_sites(container_name:)
        index.select { |k, v| v.container_mapper.name == container_name && !alias?(name: k) }
      end

      def reindex_site(name:, container_name:)
        self.class.index ||= {}
        self.class.index[name].names.each { |n| self.class.index.delete(n) } if self.class.index[name]

        index_item = IndexItem.new(name: name, container_name: container_name, controller: self)

        if index_item.etc_mapper.nil?
          self.class.index.delete(name)
          return
        end

        if self.class.index.key?(name) && self.class.index[name].etc_mapper.path != index_item.etc_mapper.path
          raise NetStatus::Exception, code: :container_site_name_conflict,
                data: { site1: self.class.index[name].etc_mapper.path.to_s, site2: index_item.etc_mapper.path.to_s }
        end

        index_item.names.each { |n| self.class.index[n] = index_item }
      end
    end
  end
end
