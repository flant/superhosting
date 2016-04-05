module SpecHelpers
  module Controller
    module Base
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def base_controller
        @base_controller ||= Superhosting::Controller::Base.new
      end

      # methods

      def base_repair(**kwargs)
        base_controller.repair
      end
    end
  end
end
