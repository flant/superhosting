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

      def model_tree(**kwargs)
        model_controller.list
      end

      def model_reconfigure(**kwargs)
        model_controller.reconfigure(**kwargs)
      end

      def model_update(**kwargs)
        model_controller.update(**kwargs)
      end
    end
  end
end
