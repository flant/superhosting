module Superhosting
  module Cli
    module Cmd
      class ContainerAdminAdd < Base
        option :container_name,
               :short => '-c NAME',
               :long  => '--container NAME',
							 :required => true

        def self.has_required_param?
          true
        end
      end
    end
  end
end