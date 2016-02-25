module Superhosting
  module Controller
    class Site < Base
      def add(name:, container_name:)

      end

      def delete(name:)

      end

      def rename(name:)

      end

      def alias(name:, logger: @logger)
        Alias.new(name: name, logger: logger)
      end
    end
  end
end