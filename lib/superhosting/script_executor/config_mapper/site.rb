module Superhosting
  module ScriptExecutor
    module ConfigMapper
      class Site < Base
        def aliases
          self.f('aliases').lines
        end
      end
    end
  end
end