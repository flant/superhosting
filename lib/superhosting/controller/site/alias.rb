module Superhosting
  module Controller
    class Site
      class Alias < Base
        def initialize(name:, **kvargs)
          raise NetStatus::Exception, { error: :logical_error, message: "Site '#{name}' doesn't exists." } unless @site_descriptor = Site.new(kvargs).site_index[name]
          super(kvargs)
        end

        def add(name:)
          return { error: :input_error, message: "Invalid alias name '#{name}' - only '#{Site::DOMAIN_NAME_FORMAT}' are allowed" } if name !~ Site::DOMAIN_NAME_FORMAT
          write_if_not_exist(@site_descriptor[:site].aliases._path, name)
        end

        def delete(name:)
          remove_line_from_file(@site_descriptor[:site].aliases._path, name)
        end
      end
    end
  end
end