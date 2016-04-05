module SpecHelpers
  module Controller
    module Model
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def model_controller
        @model_controller ||= Superhosting::Controller::Model.new
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
    end
  end
end
