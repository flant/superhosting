module Superhosting
  module Controller
    class Site
      class Alias < Base
        def initialize(name:, **kwargs)
          super(kwargs)
          @site_controller = self.get_controller(Site)
          @site_controller.existing_validation(name: name).net_status_ok!

          site = @site_controller.index[name]
          @site_mapper = site[:mapper]
          @aliases_mapper = site[:mapper].aliases_mapper
          @container_mapper = site[:container_mapper]
        end

        def add(name:)
          if (resp = self.not_existing_validation(name: name)).net_status_ok? and
            (resp = @site_controller.adding_validation(name: name)).net_status_ok?
            @aliases_mapper.append_line!(name)
            @site_controller.reconfigure(name: @site_mapper.name)

            @site_controller.reindex_site(name: @site_mapper.name, container_name: @container_mapper.name)
          end
          resp
        end

        def delete(name:)
          if (resp = self.existing_validation(name: name)).net_status_ok?
            @aliases_mapper.remove_line!(name)
            @site_controller.reconfigure(name: @site_mapper.name)

            @site_controller.reindex_site(name: @site_mapper.name, container_name: @container_mapper.name)
          end
          resp
        end

        def existing_validation(name:)
          @aliases_mapper.lines.include?(name) ?  {} : { error: :logical_error, code: :alias_does_not_exists, data: { name: name } }
        end

        def not_existing_validation(name:)
          self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :alias_exists, data: { name: name } } : {}
        end
      end
    end
  end
end