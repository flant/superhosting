module Superhosting
  module Cli
    module Cmd
      class ContainerTree < Base
        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          ModelTree.show_models_tree(data)
        end
      end
    end
  end
end