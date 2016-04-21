module Superhosting
  module Cli
    module Cmd
      class AdminContainerAdd < Base
        include Helper::Options::Admin

        def self.required_param?
          true
        end
      end
    end
  end
end
