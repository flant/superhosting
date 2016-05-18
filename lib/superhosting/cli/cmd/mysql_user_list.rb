module Superhosting
  module Cli
    module Cmd
      class MysqlUserList < Base
        include Helper::Options::List
        include Helper::Options::NotRequiredContainer

        def self.after_action(data, config)
          show_mysql_list(data, config)
        end
      end
    end
  end
end
