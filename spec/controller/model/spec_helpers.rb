module SpecHelpers
  module Controller
    module Model
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def model_controller
        @model_controller ||= Superhosting::Controller::Model.new(docker_api: docker_api)
      end

      # methods

      def model_list(**kwargs)
        model_controller.list
      end

      def model_reconfig(**kwargs)
        model_controller.reconfig(**kwargs)
      end
    end
  end
end
