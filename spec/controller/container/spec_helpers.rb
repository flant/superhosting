module SpecHelpers
  module Controller
    module Container
      def container_controller
        @container_controller ||= Superhosting::Controller::Container.new
      end

      def docker_api
        @docker_api ||= Superhosting::DockerApi.new
      end

      def container_add(**kwargs)
        container_controller.add(**kwargs)
        expect(docker_api.container_info(kwargs[:name])).not_to be_nil
      end
    end # Container
  end # Controller
end # SpecHelpers
