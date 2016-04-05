module SpecHelpers
  module Helpers
    module Base
      def controller
        @controller ||= Superhosting::Base.new
      end

      def config
        self.controller.config
      end

      def lib
        self.controller.lib
      end

      def etc
        PathMapper.new('/etc')
      end

      def web
        PathMapper.new('/web')
      end

      def docker_api
        @docker_api ||= if @with_docker
          Superhosting::DockerApi.new
        else
          docker_instance = instance_double('Superhosting::DockerApi')
          allow(docker_instance).to receive(:method_missing) {|method, *args, &block| true }
          [:container_list,:grab_container_options].each {|m| allow(docker_instance).to receive(m) {|options| [] } }
          docker_instance
        end
      end
    end
  end
end