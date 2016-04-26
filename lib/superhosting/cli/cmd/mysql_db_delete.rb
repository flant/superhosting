module Superhosting
  module Cli
    module Cmd
      class MysqlDbDelete < Base
        include Helper::Options::NotRequiredContainer

        def self.required_param?
          true
        end
      end
    end
  end
end
