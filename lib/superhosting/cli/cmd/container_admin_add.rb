module Superhosting
  module Cli
    module Cmd
      class ContainerAdminAdd < Base
        include Helper::Options::Container

        def self.required_param?
          true
        end
      end
    end
  end
end
