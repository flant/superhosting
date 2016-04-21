module Superhosting
  module CompositeMapper
    class Site < Base
      def aliases
        aliases_mapper.lines
      end

      def aliases_mapper
        self.lib.parent.parent.sites.f(self.name).aliases
      end
    end
  end
end
