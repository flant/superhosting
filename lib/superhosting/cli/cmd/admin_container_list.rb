module Superhosting
  module Cli
    module Cmd
      class AdminContainerList < Base
        include Helper::Options::List
        include Helper::Options::Admin

        def self.after_action(data, config)
          show_admin_container_list(data, config)
        end
      end
    end
  end
end