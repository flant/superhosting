module Superhosting
  module Cli
    module Cmd
      class ContainerAdminList < Base
        option :container_name,
               :short => '-c NAME',
               :long  => '--container NAME',
               :required => true
      end
    end
  end
end