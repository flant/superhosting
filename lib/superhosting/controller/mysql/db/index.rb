module Superhosting
  module Controller
    class Mysql
      class Db
        class << self; attr_accessor :index end

        def initialize(**kwargs)
          super
          @container_controller = get_controller(Container)
          @mysql_controller = get_controller(Mysql)
          @client = @mysql_controller.client
          index
        end

        def container_dbs(container_name:)
          self.class.index.select { |u| u.start_with? container_name }
        end

        def index
          self.class.index ||= reindex
        end

        def reindex
          @config.containers.grep_dirs.each do |container_mapper|
            reindex_container(container_name: container_mapper.name)
          end
          self.class.index ||= {}
        end

        def reindex_container(container_name:)
          self.class.index ||= {}
          container_dbs(container_name: container_name).each { |k, _v| self.class.index.delete(k) }
          user_controller = get_controller(User)
          @client.query("SHOW DATABASES LIKE '#{container_name}_%'").tap do |result|
            field_name = result.fields.first
            result.each do |obj|
              self.class.index[obj[field_name]] = user_controller.grant_index[obj[field_name]] || []
            end
          end
        end
      end
    end
  end
end
