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

      def alternative_name(name:)
        container_controller = get_controller(Container)
        container_name, name = name.split('_')
        unless container_controller.available_validation(name: container_name).net_status_ok?
          raise NetStatus::Exception, { code: :container_name_is_not_specified }
        end
        [container_name, name]
      end

      def grant(user_name:, database_name:)
        user_controller = get_controller(User)
        database_controller = get_controller(Db)
        if (resp = user_controller.existing_validation(name: user_name)).net_status_ok? &&
           (resp = database_controller.existing_validation(name: database_name)).net_status_ok?
          _grant(user_name: user_name, database_name: database_name)
        end
        resp
      end

      def _grant(user_name:, database_name:)
        user_controller = get_controller(User)
        container_name = user_name.split('_').first
        client.query("GRANT ALL PRIVILEGES ON #{database_name}.* TO '#{user_name}'@'%' WITH GRANT OPTION ")
        user_controller.reindex_container(container_name: container_name)
      end

      def revoke(user_name:, database_name:)
        user_controller = get_controller(User)
        database_controller = get_controller(Db)
        if (resp = user_controller.existing_validation(name: user_name)).net_status_ok? &&
           (resp = database_controller.existing_validation(name: database_name)).net_status_ok?
          _revoke(user_name: user_name, database_name: database_name)
        end
        resp
      end

      def _revoke(user_name:, database_name:)
        user_controller = get_controller(User)
        container_name = user_name.split('_').first
        client.query("REVOKE ALL PRIVILEGES ON #{database_name}.* FROM '#{user_name}'@'%'")
        user_controller.reindex_container(container_name: container_name)
      end
    end
  end
end
