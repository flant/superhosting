module Superhosting
  module Cli
    module Cmd
      class AdminAdd < Base
        option :verbosity,
               :short => "-v",
               :long  => "--verbose",
               :description => "More verbose output. Use twice for max verbosity",
               :proc => Proc.new { verbosity_level += 1 },
               :default => 0

        def run
        end
      end
    end
  end
end