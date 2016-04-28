module Superhosting
  module Controller
    class Mux
      def adding_validation(name:)
        @docker_api.container_rm_inactive!(name)
        contianer_name = index[name][:mapper].container_name
        not_running_validation(name: contianer_name)
      end

      def useable_validation(name:)
        existing_validation(name: name).net_status_ok!
        index[name][:containers].empty? ? { error: :logical_error, code: :mux_does_not_used, data: { name: name } } : {}
      end

      def existing_validation(name:)
        @config.muxs.f(name).dir? ? {} : { error: :logical_error, code: :mux_does_not_exists, data: { name: name } }
      end

      def not_running_validation(name:)
        container_name = index[name][:mapper].container_name
        @container_controller.not_running_validation(name: container_name).net_status_ok? ? {} : { error: :logical_error, code: :mux_is_running, data: { name: container_name } }
      end

      def running_validation(name:)
        container_name = index[name][:mapper].container_name
        @container_controller.running_validation(name: container_name).net_status_ok? ? {} : { error: :logical_error, code: :mux_is_not_running, data: { name: container_name } }
      end
    end
  end
end
