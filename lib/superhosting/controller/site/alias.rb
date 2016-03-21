module Superhosting
  module Controller
    class Site
      class Alias < Base
        def initialize(name:, **kwargs)
          super(kwargs)
          @site_controller = self.get_controller(Site)
          @site_controller.existing_validation(name: name).net_status_ok!
          @site_descriptor = @site_controller.site_index[name]
        end

        def add(name:)
          if (resp = self.not_existing_validation(name: name)).net_status_ok? and
            (resp = @site_controller.adding_validation(name: name)).net_status_ok?
            @site_descriptor[:site].aliases.append!(name)
            @site_controller._reconfig(@site_descriptor[:site].name, @site_descriptor[:container].name)
          end
          resp
        end

        def delete(name:)
          if self.not_existing_validation(name: name).net_status_ok?
            self.debug("Alias '#{name}' has already been deleted")
          else
            aliases_mapper = @site_descriptor[:site].aliases
            pretty_remove(aliases_mapper.path, name)
            @site_controller._reconfig(@site_descriptor[:site].name, @site_descriptor[:container].name)
            {}
          end
        end

        def existing_validation(name:)
          check_in_file(@site_descriptor[:site].aliases.path, name) ?  {} : { error: :logical_error, code: :alias_does_not_exists, data: { name: name } }
        end

        def not_existing_validation(name:)
          self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :alias_exists, data: { name: name } } : {}
        end
      end
    end
  end
end