module Superhosting
  module Cli
    module Cmd
      class ModelTree < Base
        class << self
          def has_required_param?
            true
          end

          def after_action(data, config)
            show_models_tree(data)
          end
        end
      end
    end
  end
end