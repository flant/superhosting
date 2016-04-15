module Superhosting
  module Cli
    module Cmd
      class ContainerModel < Base
        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          self.info(data)
        end
      end
    end
  end
end