module Superhosting
  module Cli
    module Cmd
      class AdminContainerDelete < Base
        option :admin_name,
               :short => '-a',
               :long  => '--admin'

        def run
        end
      end
    end
  end
end