module Superhosting
  module CompositeMapper
    class Site < Base
      def aliases
        aliases_mapper.lines
      end

      def aliases_mapper
        lib.parent.parent.sites.f(name).aliases
      end
    end
  end
end
