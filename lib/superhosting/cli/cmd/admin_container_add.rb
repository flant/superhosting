module Superhosting
  module Cli
    module Cmd
      class AdminContainerAdd < Base
        option :admin_name,
               :short => '-a',
               :long  => '--admin'

        def run
        end
      end
    end
  end
end