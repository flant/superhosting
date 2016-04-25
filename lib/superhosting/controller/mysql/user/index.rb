module Superhosting
  module Controller
    class Mysql
      class User
        class << self; attr_accessor :index end

        def initialize(**kwargs)
          super
          @container_controller = get_controller(Container)
          @mysql_controller = get_controller(Mysql)
          @db_controller = get_controller(Db)
          @grand_controller = get_controller(Grant)
          @client = @mysql_controller.client
          index
        end

        def index
          self.class.index ||= reindex
        end

        def reindex
          @config.containers.grep_dirs.each do |container_mapper|
            reindex_container_users(container_name: container_mapper.name)
          end
          self.class.index ||= {}
        end

        def reindex_container_users(container_name:)
          info(@client.prepare("select User from mysql.user where Host = '%' and User like ?").execute("'#{container_name}_%'").to_a.inspect)
        end
      end
    end
  end
end
