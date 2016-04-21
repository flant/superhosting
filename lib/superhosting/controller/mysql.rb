module Superhosting
  module Controller
    class Mysql < Base
      def db
        get_controller(Db)
      end

      def user
        get_controller(User)
      end

      def grant
      end
    end
  end
end
