module Superhosting
  module Cli
    module Cmd
      class ContainerRestore < Base
        option :restore_from,
               :long  => '--from'

        option :model,
               :short => '-m',
               :long  => '--model'

        option :mail,
               :long  => '--mail MAIL'

        option :admin_mail,
               :long  => '--admin-mail MAIL'

        def self.has_required_param?
          true
        end
      end
    end
  end
end