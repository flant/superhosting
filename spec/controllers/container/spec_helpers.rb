module SpecHelpers
  module Controllers
    module Container
      def container_controller
        @container_controller ||= Superhosting::Controllers::Container.new
      end

      def add_container(**kwargs)
        container_controller.add(**kwargs)
      end
    end # Container
  end # Controllers
end # SpecHelpers
