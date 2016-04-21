module Superhosting
  module Cli
    module Cmd
      class ContainerList < Base
        include Helper::Options::List
        include Helper::Options::State

        def self.after_action(data, config)
          show_container_list(data, config)
        end
      end
    end
  end
end
