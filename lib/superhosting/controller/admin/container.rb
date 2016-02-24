module Superhosting
  module Controller
    class Admin
      class Container < Base
        def initialize(name:, **kvargs)
          @admin_name = name
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