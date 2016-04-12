module Superhosting
  module Cli
    module Cmd
      class ModelList < Base
        def self.after_action(data, config)
          self.info(data)
        end
      end
    end
  end
end