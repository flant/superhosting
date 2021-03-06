module Superhosting
  module Controller
    class Mysql
      class Db
        class << self; attr_accessor :index end

        def initialize(**kwargs)
          super
          @container_controller = controller(Container)
          @mysql_controller = controller(Mysql)
          index
        end

        def container_dbs(container_name:)
          self.class.index.select { |u| u.start_with? "#{container_name}_" }
        end

        def index
          self.class.index ||= reindex
        end

        def reindex
          self.class.index = {}
          @container_controller.index.keys.each { |container_name| reindex_container(container_name: container_name) }
          self.class.index
        end

        def reindex_container(container_name:)
          self.class.index ||= {}
          container_dbs(container_name: container_name).each { |k, _v| self.class.index.delete(k) }
          user_controller = controller(User)
          @mysql_controller.query("SHOW DATABASES LIKE '#{container_name}_%'").tap do |result|
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
