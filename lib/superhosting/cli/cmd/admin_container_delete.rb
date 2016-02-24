module Superhosting
  module Cli
    module Cmd
      class AdminContainerDelete < Base
        option :admin_name,
               :short => '-a NAME',
               :long  => '--admin NAME',
							 :required => true

        def self.has_required_param?
          true
        end
      end
    end
  end
end