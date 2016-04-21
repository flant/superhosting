module Superhosting
  module Cli
    module Cmd
      class AdminList < Base
        include Helper::Options::List

        def self.after_action(data, config)
          show_admin_list(data, config)
        end
      end
    end
  end
end
