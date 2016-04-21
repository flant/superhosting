module Superhosting
  module Cli
    module Cmd
      class ContainerModelName < Base
        include Helper::Options::Container

        def self.after_action(data, _config)
          show_data(data)
        end
      end
    end
  end
end
