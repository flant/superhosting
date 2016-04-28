module Superhosting
  module Controller
    class Mysql
      class User
        class << self; attr_accessor :index, :grant_index end

        def initialize(**kwargs)
          super
          @container_controller = get_controller(Container)
          @mysql_controller = get_controller(Mysql)
          @client = @mysql_controller.client
          index
        end

        def index
          self.class.index ||= reindex
        end

        def grant_index
          self.class.grant_index ||= reindex
        end

        def container_users(container_name:)
          self.class.index.select { |u| u.start_with? container_name }
        end

        def container_grants(container_name:)
          self.class.grant_index.select { |u| u.start_with? container_name }
        end

        def reindex
          @config.containers.grep_dirs.each do |container_mapper|
            reindex_container(container_name: container_mapper.name)
          end
          self.class.index ||= {}
        end

        def reindex_grant
          reindex
          self.class.grant_index ||= {}
        end

        def reindex_container(container_name:)
          self.class.index ||= {}
          self.class.grant_index ||= {}
          container_users(container_name: container_name).each { |k, _v| self.class.index.delete(k) }
          container_grants(container_name: container_name).each { |k, _v| self.class.index.delete(k) }

          @client.query("select User from mysql.user where Host = '%' and User like '#{container_name}_%'").each do |obj|
            name = obj['User']
            @client.query("SHOW GRANTS FOR #{name}@'%'").tap do |result|
              field_name = result.fields.first
              index_name = (self.class.index[name] ||= [])
              result.each do |grant_obj|
                grant = grant_obj[field_name]
                next if grant.start_with? 'GRANT USAGE ON *.*'
                grant_index_name = (self.class.grant_index[grant[/ON `(.*)`/, 1]] ||= [])
                index_name << grant[/ON `(.*)`/, 1]
                grant_index_name << name unless grant_index_name.include? name
              end
            end
          end
        end
      end
    end
  end
end
