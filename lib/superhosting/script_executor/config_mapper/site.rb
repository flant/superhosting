module Superhosting
  module ScriptExecutor
    module ConfigMapper
      class Site < Base
        def aliases
          self.f('aliases', default: [])
        end
      end
    end
  end
end