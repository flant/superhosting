module Superhosting
  module CompositeMapper
    class Container < Base
      def config
        self.lib.config
      end
    end
  end
end