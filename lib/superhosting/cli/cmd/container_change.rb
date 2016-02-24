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

        def self.has_required_param?
          true
        end
      end
    end
  end
end