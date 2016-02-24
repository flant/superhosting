module Superhosting
  module Controller
    class Admin < Base
      def add(name:)

      end

      def delete(name:)

      end

      def passwd(name:, generate: nil)

      end

      def container(name:)
        Container.new(name: name, logger: @logger)
      end
    end
  end
end