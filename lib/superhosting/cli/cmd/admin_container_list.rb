module Superhosting
  module Cli
    module Cmd
      class AdminContainerList < Base
        option :admin_name,
               :short => '-a NAME',
               :long  => '--admin NAME',
               :required => true
      end
    end
  end
end