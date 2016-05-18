module Superhosting
  module Controller
    class Mysql
      class User < Base
        def list(container_name: nil)
          if container_name.nil?
            users = index
          elsif (resp = @container_controller.available_validation(name: container_name)).net_status_ok?
            users = container_users(container_name: container_name)
          else
            resp
          end

          { data: users.map { |name, _grants| _inspect(name: name) } }
        end

        def add(name:, container_name: nil, generate: false, databases: [])
          container_name, name = @mysql_controller.alternative_name(name: name) unless container_name
          user_name = [container_name, name].join('_')
          databases.map! { |db| db.start_with?(container_name) ? db : [container_name, db].join('_') }
          db_controller = controller(Db)
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
          user_controller = controller(Controller::User)
          password = user_controller._create_password(generate: generate)[:password]

          debug_operation(desc: { code: :mysql_user, data: { name: name } }) do |&blk|
            with_dry_run do |dry_run|
              @client.query("CREATE USER #{name}@'%' IDENTIFIED BY '#{password}'") unless dry_run
              blk.call(code: :added)
            end
          end

          databases.each {|db_name| @mysql_controller._grant(user_name: name, database_name: db_name) }
          reindex_container(container_name: container_name)
          password if generate
        end

        def delete(name:)
          if (resp = existing_validation(name: name)).net_status_ok?
            _delete(name: name)
          end
          resp
        end

        def _delete(name:)
          container_name = name.split('_').first
          index[name].each { |db_name| @mysql_controller._revoke(user_name: name, database_name: db_name) }

          debug_operation(desc: { code: :mysql_user, data: { name: name } }) do |&blk|
            with_dry_run do |dry_run|
              @client.query("DROP USER #{name}") unless dry_run
              blk.call(code: :dropped)
            end
          end

          reindex_container(container_name: container_name)
        end

        def inspect(name:)
          if (resp = existing_validation(name: name)).net_status_ok?
            { data: _inspect(name: name) }
          else
            resp
          end
        end

        def _inspect(name:)
          {
              'name' => name,
              'grants' => index[name]
          }
        end
      end
    end
  end
end
