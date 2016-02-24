module Superhosting
  module Controller
    class Container
      class Admin < Base
        def initialize(name:, **kvargs)
          @container_name = name
          super(kvargs)
        end

        def list

        end

        def add(name:)

        end

        def delete(name:)

        end
      end
    end
  end
end