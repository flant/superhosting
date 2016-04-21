module Superhosting
  module Cli
    module Error
      class AmbiguousCommand < Base
        def initialize(msg: 'Ambiguous command', commands:, path: '')
          super(error: "#{msg}: #{path.join(' ')} (#{commands.join('|')})")
        end
      end
    end
  end
end
