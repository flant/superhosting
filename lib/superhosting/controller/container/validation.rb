module Superhosting
  module Controller
    class Container
      NAME_FORMAT = /^[a-zA-Z0-9][a-zA-Z0-9_.-]+$/

      def base_validation(name:)
        @docker_api.container_rm_inactive!(name)
        [self, controller(User)].each { |controller| controller.container_name_validation(name: name).net_status_ok! }
        {}
      end

      def container_name_validation(name:)
        (name !~ NAME_FORMAT) ? { error: :input_error, code: :invalid_container_name, data: { name: name, regex: NAME_FORMAT } } : {}
      end

      def adding_validation(name:)
        if (resp = base_validation(name: name)).net_status_ok?
          resp = not_running_validation(name: name)
        end
        resp
      end

      def running_validation(name:)
        @docker_api.container_running?(name) ? {} : { error: :logical_error, code: :container_is_not_running, data: { name: name } }
      end

      def not_running_validation(name:)
        @docker_api.container_not_running?(name) ? {} : { error: :logical_error, code: :container_is_running, data: { name: name } }
      end

      def existing_validation(name:)
        index.include?(name) ? {} : { error: :logical_error, code: :container_does_not_exists, data: { name: name } }
      end

      def not_existing_validation(name:)
        existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :container_exists, data: { name: name } } : {}
      end

      def available_validation(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          resp = (index[name].state_mapper.value == 'up') ? {} : { error: :logical_error, code: :container_is_not_available, data: { name: name } }
        end
        resp
      end
    end
  end
end
