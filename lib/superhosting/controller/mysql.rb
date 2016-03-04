module Superhosting
  module Controller
    class Mysql < Base
      def db
        self.get_controller(Db)
      end

      def user
        self.get_controller(User)
      end

      def grant

      end
    end
  end
end