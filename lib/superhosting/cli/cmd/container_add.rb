module Superhosting
  module Cli
    module Cmd
      class ContainerAdd < Base
        include Helper::Options::Model

        def self.required_param?
          true
        end
      end
    end
  end
end
