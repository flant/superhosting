module Superhosting
  module Cli
    module Cmd
      class ContainerChange < Base
        option :model,
               :short => '-m',
               :long  => '--model'

        option :mail,
               :long  => '--mail'

        option :admin_mail,
               :long  => '--admin-mail'

        def run
          
        end
      end
    end
  end
end