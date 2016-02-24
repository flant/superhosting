module Superhosting
  module Cli
    module Cmd
      class AdminPasswd < Base
        option :generate,
               :short => '-g',
               :long  => '--generate'

        def self.has_required_param?
          true
        end
      end
    end
  end
end