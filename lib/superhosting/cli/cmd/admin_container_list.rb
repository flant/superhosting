module Superhosting
  module Cli
    module Cmd
      class AdminContainerList < Base
        option :admin_name,
               :short => '-a NAME',
               :long  => '--admin NAME',
               :required => true

        option :json,
               :long  => '--json',
               :boolean => true

        def self.after_action(data, config)
          show_admin_container_list(data, config)
        end
      end
    end
  end
end