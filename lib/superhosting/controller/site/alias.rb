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
            file_append(@site_descriptor[:site].aliases.path, name)
          else
            resp
          end
        end

        def delete(name:)
          if self.not_existing_validation(name: name).net_status_ok?
            self.debug("Alias '#{name}' has already been deleted")
          else
            aliases_mapper = @site_descriptor[:site].aliases
            pretty_remove(aliases_mapper.path, name)
            aliases_mapper.delete! if aliases_mapper.empty?
            {}
          end
        end

        def existing_validation(name:)
          check_in_file(@site_descriptor[:site].aliases.path, name) ?  {} : { error: :logical_error, code: :alias_does_not_exists, data: { name: name } }
        end

        def not_existing_validation(name:)
          self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :alias_already_exists, data: { name: name } } : {}
        end
      end
    end
  end
end