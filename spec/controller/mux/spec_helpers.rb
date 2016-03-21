module SpecHelpers
  module Controller
    module Mux
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def mux_controller
        @mux_controller ||= Superhosting::Controller::Mux.new(docker_api: docker_api)
      end

      # methods

      def mux_reconfig(**kwargs)
        mux_controller.reconfig(**kwargs)
      end
    end
  end
end
