module Superhosting
  module Controller
    class Mysql < Base
      def db
        controller(Db)
      end

      def user
        controller(User)
      end

      def grant
      end
    end
  end
end
