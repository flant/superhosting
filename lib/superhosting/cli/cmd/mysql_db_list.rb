module Superhosting
  module Cli
    module Cmd
      class MysqlDbList < Base
        include Helper::Options::List
        include Helper::Options::Container

        def self.after_action(data, _config)
          show_list(data)
        end
      end
    end
  end
end
