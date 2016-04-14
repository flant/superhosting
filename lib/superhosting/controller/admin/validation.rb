module Superhosting
  module Controller
    class Admin
      def existing_validation(name:)
        (@admins_mapper.f(name)).nil? ? { error: :logical_error, code: :admin_does_not_exists, data: { name: name } } : {}
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :admin_exists, data: { name: name } } : {}
      end
    end
  end
end