module Superhosting
  module Cli
    module Cmd
      class ContainerModelName < Base
        option :container_name,
               :short => '-c NAME',
               :long  => '--container NAME',
               :required => true

        def self.after_action(data, config)
          self.info(data)
        end
      end
    end
  end
end