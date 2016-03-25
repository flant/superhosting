module Superhosting
  module CompositeMapper
    class Site < Base
      def aliases
        self.f('aliases').lines
      end
    end
  end
end