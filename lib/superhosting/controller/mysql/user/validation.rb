module Superhosting
  module Controller
    class Mysql
      class User
        NAME_FORMAT = /^[a-zA-Z0-9._-]{1,15}$/

        def adding_validation(name:)
          resp = name_validation(name: name)
          resp = not_existing_validation(name: name) if resp.net_status_ok?
          resp
        end

        def name_validation(name:)
          name !~ NAME_FORMAT ? { error: :input_error, code: :invalid_mysql_user_name, data: { name: name, regex: NAME_FORMAT } } : {}
        end

        def existing_validation(name:)
          index[name].nil? ? { error: :logical_error, code: :mysql_user_does_not_exists, data: { name: name } } : {}
        end

        def not_existing_validation(name:)
          index[name].nil? ? {} : { error: :logical_error, code: :mysql_user_exists, data: { name: name } }
        end
      end
    end
  end
end
