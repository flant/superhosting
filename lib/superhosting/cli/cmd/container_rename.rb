module Superhosting
  module Cli
    module Cmd
      class ContainerRename < Base
        include Helper::Options::NewName

        def self.has_required_param?
          true
        end
      end
    end
  end
end