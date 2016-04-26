module Superhosting
  module Controller
    class Mysql
      class Db
        NAME_FORMAT = /^[a-zA-Z0-9._-]{1,64}$/

        def adding_validation(name:)
          resp = name_validation(name: name)
          resp = not_existing_validation(name: name) if resp.net_status_ok?
          resp
        end

        def name_validation(name:)
          name !~ NAME_FORMAT ? { error: :input_error, code: :invalid_mysql_db_name, data: { name: name, regex: NAME_FORMAT } } : {}
        end

        def existing_validation(name:)
          index[name].nil? ? { error: :logical_error, code: :mysql_db_does_not_exists, data: { name: name } } : {}
        end

        def not_existing_validation(name:)
          index[name].nil? ? {} : { error: :logical_error, code: :mysql_db_exists, data: { name: name } }
        end
      end
    end
  end
end
