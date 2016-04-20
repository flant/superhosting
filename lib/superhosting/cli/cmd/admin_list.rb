module Superhosting
  module Cli
    module Cmd
      class AdminList < Base
        option :json,
               :long  => '--json',
               :boolean => true

        def self.after_action(data, config)
          show_admin_list(data, config)
        end
      end
    end
  end
end