module Superhosting
  module Controller
    class Model
      def useable_validation(name:)
        index.include?(name) ? {} : { error: :logical_error, code: :model_does_not_used, data: { name: name } }
      end

      def existing_validation(name:)
        @config.models.f(name).dir? ? {} : { error: :logical_error, code: :model_does_not_exists, data: { name: name } }
      end
    end
  end
end
