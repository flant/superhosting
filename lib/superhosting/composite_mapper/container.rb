module Superhosting
  module CompositeMapper
    class Container < Base
      def config
        lib.config
      end

      def container_name
        etc.name
      end
    end
  end
end
