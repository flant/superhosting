module Superhosting
  module Controller
    class Container < Base
      def list

      end

      def add(name:, model: :required, mail: nil, admin_mail: :required)

      end

      def delete(name:)

      end

      def change(name:, model: :required, mail: nil, admin_mail: :required)

      end

      def update(name:)

      end

      def reconfig(name:)

      end

      def save(name:, to:)

      end

      def restore(name:, from:, model: :required, mail: nil, admin_mail: :required)

      end

      def admin(name:, logger: @logger)
        Admin.new(name: name, logger: logger)
      end
    end
  end
end
