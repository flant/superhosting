module Superhosting
  module Controller
    class User
      NAME_FORMAT = /^[a-zA-Z][-a-zA-Z0-9_]{,31}$/

      def adding_validation(name:, container_name:)
        resp = self.not_existing_validation(name: name, container_name: container_name)
        resp = self.name_validation(name: name) if resp.net_status_ok?
        resp
      end

      def name_validation(name:)
        name !~ NAME_FORMAT ? { error: :input_error, code: :invalid_user_name, data: { name: name, regex: NAME_FORMAT } } : {}
      end

      def container_name_validation(name:)
        name_validation(name: name).net_status_ok? ? {} : { error: :input_error, code: :invalid_container_name_by_user_format, data: { name: name, regex: NAME_FORMAT } }
      end

      def existing_validation(name:, container_name:)
        user_name = "#{container_name}_#{name}"
        PathMapper.new('/etc/passwd').check(user_name) ? {} : { error: :logical_error, code: :user_does_not_exists, data: { name: user_name } }
      end

      def not_existing_validation(name:, container_name:)
        self.existing_validation(name: name, container_name: container_name).net_status_ok? ? { error: :logical_error, code: :user_exists, data: { name: "#{container_name}_#{name}" } } : {}
      end
    end
  end
end
