module Superhosting
  module Cli
    module Cmd
      class ContainerList < Base
        option :state,
               :long  => '--state',
               :boolean => true

        option :json,
               :long  => '--json',
               :boolean => true

        def self.after_action(data, config)
          show_container_list(data, config)
        end
      end
    end
  end
end