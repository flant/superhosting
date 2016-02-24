module Superhosting
  module Controller
    class Site
      class Alias < Base
        def initialize(name:, **kvargs)
          @site_name = name
          super(kvargs)
        end

        def add(name:)

        end

        def delete(name:)

        end
      end
    end
  end
end