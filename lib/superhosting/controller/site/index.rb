module Superhosting
  module Controller
    class Site
      def initialize(**kwargs)
        super(**kwargs)
        @container_controller = self.get_controller(Container)
        self.index
      end

      def index
        @@index ||= self.reindex
      end

      def reindex
        @config.containers.grep_dirs.each do |container_mapper|
          reindex_container_sites(container_name: container_mapper.name)
        end
        @@index ||= {}
      end

      def reindex_container_sites(container_name:)
        @config.containers.f(container_name).sites.grep_dirs.each do |site_mapper|
          self.reindex_site(name: site_mapper.name, container_name: container_name)
        end
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

        names = ([mapper.name] + mapper.aliases)
        names.each {|name| @@index[name] = { mapper: mapper, container_mapper: container_mapper, state_mapper: state_mapper, aliases: names } }
      end
    end
  end
end