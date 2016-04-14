module Superhosting
  module Controller
    class Model
      def useable_validation(name:)
        self.index.include?(name) ? {} : { error: :logical_error, code: :model_does_not_used, data: { name: name } }
      end

      def existing_validation(name:)
        self._list.include?(name) ? {} : { error: :logical_error, code: :model_does_not_exists, data: { name: name } }
      end
    end
  end
end