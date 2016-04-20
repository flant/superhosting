module Superhosting
  module Cli
    module Cmd
      class ContainerModelTree < Base
        include Helper::Options::Container

        def self.after_action(data, _config)
          show_models_tree(data)
        end
      end
    end
  end
end