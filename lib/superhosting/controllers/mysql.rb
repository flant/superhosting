module Superhosting
  module Controllers
    class Mysql < Controller
      def db
        Db.new
      end

      def user
        User.new
      end

      def grant

      end
    end
  end
end