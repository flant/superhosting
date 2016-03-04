module Superhosting
  module Controller
    class Site
      class Alias < Base
        def initialize(name:, **kwargs)
          super(kwargs)
          @site = self.get_controller(Site)
          @site.existing_validation(name: name).net_status_ok!
          @site_descriptor = @site.site_index[name]
        end

        def add(name:)
          if self.existing_validation(name: name).net_status_ok?
            self.debug("Alias '#{name}' already exists")
          elsif (resp = @site.adding_validation(name: name)).net_status_ok?
            file_write(@site_descriptor[:site].aliases._path, name)
          else
            resp
          end
        end

        def delete(name:)
          if self.not_existing_validation(name: name).net_status_ok?
            self.debug("Alias '#{name}' has already been deleted")
          else
            pretty_remove(@site_descriptor[:site].aliases._path, name)
            {}
          end
        end

        def existing_validation(name:)
          check_in_file(@site_descriptor[:site].aliases._path, name) ?  {} : { error: :logical_error, message: "Alias '#{name}' doesn't exists" }
        end

        def not_existing_validation(name:)
          self.existing_validation.net_status_ok? ? {}: { error: :logical_error, message: "Alias '#{name}' already exists" }
        end
      end
    end
  end
end