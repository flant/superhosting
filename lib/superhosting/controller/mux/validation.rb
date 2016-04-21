module Superhosting
  module Controller
    class Mux
      def adding_validation(name:)
        @docker_api.container_rm_inactive!(name)
        self.not_running_validation(name: self._container_name(name: name))
      end

      def useable_validation(name:)
        self.index.include?(name) ? {} : { error: :logical_error, code: :mux_does_not_used, data: { name: name } }
      end

      def existing_validation(name:)
        @config.muxs.f(name).dir? ? {} : { error: :logical_error, code: :mux_does_not_exists, data: { name: name } }
      end

      def not_running_validation(name:)
        @container_controller.not_running_validation(name: self._container_name(name: name)).net_status_ok? ? {} : { error: :logical_error, code: :mux_is_running, data: { name: name } }
      end

      def running_validation(name:)
        @container_controller.running_validation(name: self._container_name(name: name)).net_status_ok? ? {} : { error: :logical_error, code: :mux_is_not_running, data: { name: name } }
      end
    end
  end
end
