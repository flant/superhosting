module SpecHelpers
  module Controller
    module Base
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def base_controller
        @base_controller ||= Superhosting::Controller::Base.new(docker_api: docker_api)
      end

      # methods

      def base_repair(**kwargs)
        base_controller.repair
      end

      def base_update(**kwargs)
        base_controller.update
      end
    end
  end
end
