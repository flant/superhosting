module Superhosting
  module Controller
    class Mysql
      class User < Base
        def add(name:, container_name:, generate: false, databases: [])
          if (resp = @container_controller.available_validation(name: container_name)).net_status_ok? &&
             (resp = adding_validation(name: name, container_name: container_name)).net_status_ok? &&
             (databases.all? { |db_name| @db_controller.existing_validation(name: db_name).net_status_ok! })
            password = _add(name: name, container_name: container_name, generate: generate)
            @grand_controller._add(name: name, container_name: container_name, generate: generate)
            resp.merge!(data: password)
          end
          resp
        end

        def _add(name:, container_name:, generate: false)
          user_controller = get_controller(Controller::User)
          password = user_controller._create_password(generate: generate)[:password]
          @client.prepare("CREATE USER '?' IDENTIFIED BY '?'").execute("#{container_name}_#{name}@'%'", "#{password}")
          password
        end

        def delete
        end
      end
    end
  end
end
