module Superhosting
  module Cli
    module Cmd
      class ContainerReconfigure < Base
        option :model,
               :short => '-m MODEL',
               :long  => '--model MODEL'

        def self.has_required_param?
          true
        end
      end
    end
  end
end