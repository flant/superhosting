module Superhosting
  module Cli
    module Cmd
      class UserChange < Base
        include Helper::Options::UserAdd
        include Helper::Options::Container

        def self.required_param?
          true
        end
      end
    end
  end
end
