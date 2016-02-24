module Superhosting
  module Controller
    class Mysql < Base
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