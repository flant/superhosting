module Superhosting
  module Controller
    class Mysql < Base
      class << self; attr_accessor :client end

      def initialize(**kwargs)
        super
      end

      def client
        self.class.client ||= Mysql2::Client.new(host: @config.mysql.host.value,
                                                 username: @config.mysql.user.value,
                                                 password: @config.mysql.password.value)
      end

      def db
        get_controller(Db)
      end

      def user
        get_controller(User)
      end

      def grant
        get_controller(Grant)
      end
    end
  end
end
