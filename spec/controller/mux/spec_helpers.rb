module SpecHelpers
  module Controller
    module Mux
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def mux_controller
        @mux_controller ||= Superhosting::Controller::Mux.new(docker_api: docker_api)
      end

      # methods

      def mux_reconfigure(**kwargs)
        mux_controller.reconfigure(**kwargs)
      end

      def mux_update(**kwargs)
        mux_controller.update(**kwargs)
      end

      def mux_tree(**kwargs)
        mux_controller.tree(**kwargs)
      end

      def mux_inspect(**kwargs)
        mux_controller.inspect(**kwargs)
      end

      def mux_inheritance(**kwargs)
        mux_controller.inheritance(**kwargs)
      end

      def mux_options(**kwargs)
        mux_controller.options(**kwargs)
      end
    end
  end
end
