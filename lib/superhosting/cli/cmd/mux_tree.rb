module Superhosting
  module Cli
    module Cmd
      class MuxTree < Base
        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          ModelTree.show_models_tree(data, ignore_type: true)
        end
      end
    end
  end
end