module Superhosting
  module Cli
    module Cmd
      class UserList < Base
        option :container_name,
               :short => '-c NAME',
               :long  => '--container NAME',
               :required => true

        option :json,
               :long  => '--json',
               :boolean => true

        def self.after_action(data, config)
          show_user_list(data, config)
        end
      end
    end
  end
end