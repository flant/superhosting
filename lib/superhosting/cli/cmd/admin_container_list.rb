module Superhosting
  module Cli
    module Cmd
      class AdminContainerList < Base
        option :admin_name,
               :short => '-a NAME',
               :long  => '--admin NAME',
               :required => true

        def self.after_action(data, config)
          self.info(data)
        end
      end
    end
  end
end