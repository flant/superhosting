module Superhosting
  module Controller
    class Mysql
      class Db < Base
        def list(container_name:)
          if (resp = @container_controller.available_validation(name: container_name)).net_status_ok?
            { data: container_dbs(container_name: container_name).map { |k, v| { name: k, grants: v } } }
          else
            resp
          end
        end

        def add(name:, container_name: nil, users: [], generate: false)
          container_name, name = @mysql_controller.alternative_name(name: name) unless container_name
          db_name = [container_name, name].join('_')
          users.map! { |u| u.start_with?(container_name) ? u : [container_name, u].join('_') }
          user_controller = controller(User)
          if (resp = @container_controller.available_validation(name: container_name)).net_status_ok? &&
             (resp = adding_validation(name: db_name)).net_status_ok? &&
             (users.all? { |u_name| user_controller.adding_validation(name: u_name).net_status_ok! })
            { data: _add(name: db_name, users: users, generate: generate) }
          else
            resp
          end
        end

        def _add(name:, users: [], generate: false)
          debug_operation(desc: { code: :mysql_database, data: { name: name } }) do |&blk|
            with_dry_run do |dry_run|
              container_name = name.split('_').first

              @client.query("CREATE DATABASE #{name}") unless dry_run
              blk.call(code: :added)

              user_controller = controller(User)
              passwords = users.map do |user_name|
                password = user_controller._add(name: user_name, databases: [name], generate: generate )
                [user_name, password].join if generate
              end.compact
              reindex_container(container_name: container_name)
              passwords
            end
          end
        end

        def delete(name:)
          if (resp = existing_validation(name: name)).net_status_ok?
            debug_operation(desc: { code: :mysql_database, data: { name: name } }) do |&blk|
              with_dry_run do |dry_run|
                container_name = name.split('_').first
                index[name].each {|user_name| @mysql_controller._revoke(user_name: user_name, database_name: name) }

                @client.query("DROP DATABASE #{name}") unless dry_run
                blk.call(code: :dropped)

                reindex_container(container_name: container_name)
              end
            end
          end
          resp
        end

        def dump
        end

        def sql
        end
      end
    end
  end
end
