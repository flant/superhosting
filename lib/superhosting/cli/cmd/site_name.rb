module Superhosting
  module Cli
    module Cmd
      class SiteName < Base
        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          logger.info(data)
        end
      end
    end
  end
end