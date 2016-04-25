module Superhosting
  module Cli
    module Cmd
      class MysqlUserAdd < Base
        include Helper::Options::Generate
        include Helper::Options::Container
        include Helper::Options::Database

        def self.required_param?
          true
        end

        def self.after_action(data, _config)
          show_data(data)
        end
      end
    end
  end
end
