module Superhosting
  module Cli
    module Cmd
      class AdminList < Base
        def self.after_action(data, config)
          logger.info(data)
        end
      end
    end
  end
end