module Superhosting
  module Controller
    class Mysql
      class User < Base
        def list(container_name:)
          if (resp = @container_controller.available_validation(name: container_name)).net_status_ok?
            { data: container_users(container_name: container_name).map { |k, v| { 'name' => k, 'grants' => v } } }
          else
            resp
          end
        end

        def add(name:, container_name: nil, generate: false, databases: [])
          container_name, name = @mysql_controller.alternative_name(name: name) unless container_name
          user_name = [container_name, name].join('_')
          databases.map! { |db| db.start_with?(container_name) ? db : [container_name, db].join('_') }
          db_controller = get_controller(Db)
          if (resp = @container_controller.available_validation(name: container_name)).net_status_ok? &&
             (resp = adding_validation(name: user_name)).net_status_ok? &&
             (databases.all? { |db_name| db_controller.existing_validation(name: db_name).net_status_ok! })
            { data: _add(name: user_name, databases: databases, generate: generate) }
          else
            resp
          end
        end

        def _add(name:, databases: [], generate: false)
          container_name = name.split('_').first
          user_controller = get_controller(Controller::User)
          password = user_controller._create_password(generate: generate)[:password]
          @client.query("CREATE USER #{name}@'%' IDENTIFIED BY '#{password}'")
          databases.each {|db_name| @mysql_controller._grant(user_name: name, database_name: db_name) }
          reindex_container(container_name: container_name)
          password if generate
        end

        def delete(name:)
          if (resp = existing_validation(name: name)).net_status_ok?
            container_name = name.split('_').first
            index[name].each { |db_name| @mysql_controller._revoke(user_name: name, database_name: db_name) }
            @client.query("DROP USER #{name}")
            reindex_container(container_name: container_name)
          end
          resp
        end
      end
    end
  end
end
