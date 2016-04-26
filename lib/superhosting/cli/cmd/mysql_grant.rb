module Superhosting
  module Cli
    module Cmd
      class MysqlGrant < Base
        include Helper::Options::Container
        include Helper::Options::Database
        include Helper::Options::User
      end
    end
  end
end
