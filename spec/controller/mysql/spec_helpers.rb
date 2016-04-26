module SpecHelpers
  module Controller
    module Mysql
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def mysql_controller
        @mysql_controller ||= Superhosting::Controller::Mysql.new(docker_api: docker_api)
      end

      # methods

      def mysql_user_add(**kwargs)
        mysql_controller.user.add(**kwargs)
      end

      def mysql_user_delete(**kwargs)
        mysql_controller.user.delete(**kwargs)
      end

      def mysql_db_add(**kwargs)
        mysql_controller.db.add(**kwargs)
      end

      def mysql_db_delete(**kwargs)
        mysql_controller.db.delete(**kwargs)
      end

      # other

      def with_mysql_db(**kwargs, &b)
        with_container do |container_name|
          with_base('mysql_db', default: { name: @mysql_db_name, container_name: container_name }, **kwargs, &b)
        end
      end

      included do
        before :each do
          @mysql_user_name = "tMU#{SecureRandom.hex[0..3]}"
          @mysql_db_name = "tMDB#{SecureRandom.hex[0..3]}"
        end
      end
    end
  end
end
