module Superhosting
  module Controllers
    class Site < Controller
      def add(name:, container_name:)

      end

      def delete(name:)

      end

      def rename(name:)

      end

      def alias(name:)
        Alias.new(name)
      end
    end
  end
end