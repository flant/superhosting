module Superhosting
  module Cli
    module Cmd
      class ContainerAdminList < Base
        option :container_name,
               :short => '-c NAME',
               :long  => '--container NAME',
               :required => true

        def self.after_action(data, config)
          logger.info(data)
        end
      end
    end
  end
end