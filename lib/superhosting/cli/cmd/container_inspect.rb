module Superhosting
  module Cli
    module Cmd
      class ContainerInspect< Base
        def self.after_action(data, config)
          self.info(data)
        end
      end
    end
  end
end