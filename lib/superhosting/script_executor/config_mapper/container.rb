module Superhosting
  module ScriptExecutor
    module ConfigMapper
      class Container < Base
        def config
          self.lib.config
        end
      end
    end
  end
end