module Superhosting
  module Cli
    module Error
      class AmbiguousCommand < Base
        def initialize(msg: 'Ambiguous command', commands:, path: '')
          msg = "#{msg}: #{path.join(' ')} (#{commands.join('|')})"
          super(msg)
        end
      end
    end
  end
end