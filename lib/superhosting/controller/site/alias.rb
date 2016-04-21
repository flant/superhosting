module Superhosting
  module Controller
    class Site
      class Alias < Base
        def initialize(name:, **kwargs)
          super(kwargs)
          @site_controller = get_controller(Site)
          @site_controller.existing_validation(name: name).net_status_ok!

          site = @site_controller.index[name]
          @site_mapper = site[:mapper]
          @aliases_mapper = site[:mapper].aliases_mapper
          @container_mapper = site[:container_mapper]
        end

        def list
          { data: _list }
        end

        def _list
          @aliases_mapper.lines
        end

        def add(name:)
          if (resp = not_existing_validation(name: name)).net_status_ok? &&
             (resp = @site_controller.adding_validation(name: name)).net_status_ok?
            @aliases_mapper.append_line!(name)
            @site_controller.reconfigure(name: @site_mapper.name)

            @site_controller.reindex_site(name: @site_mapper.name, container_name: @container_mapper.name)
          end
          resp
        end

        def delete(name:)
          if (resp = existing_validation(name: name)).net_status_ok?
            @aliases_mapper.remove_line!(name)
            @site_controller.reconfigure(name: @site_mapper.name)

            @site_controller.reindex_site(name: @site_mapper.name, container_name: @container_mapper.name)
          end
          resp
        end

        def existing_validation(name:)
          @aliases_mapper.lines.include?(name) ? {} : { error: :logical_error, code: :alias_does_not_exists, data: { name: name } }
        end

        def not_existing_validation(name:)
          existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :alias_exists, data: { name: name } } : {}
        end
      end
    end
  end
end
