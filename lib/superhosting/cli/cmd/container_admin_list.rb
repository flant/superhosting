module Superhosting
  module Cli
    module Cmd
      class ContainerAdminList < Base
        include Helper::Options::List
        include Helper::Options::Container

        def self.after_action(data, config)
          show_container_admin_list(data, config)
        end
      end
    end
  end
end
