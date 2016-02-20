module Superhosting
  module Controllers
    class Container < Controller
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

      def admin(name:)
        Admin.new(name)
      end
    end
  end
end
