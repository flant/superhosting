module Superhosting
  module Controllers
    class Admin < Controller
      def add(name)

      end

      def delete(name)

      end

      def passwd(name, generate: nil)

      end

      def container(name)
        Container.new(name)
      end
    end
  end
end