module Superhosting
  module Cli
    module Cmd
      class ModelTree < Base
        class << self
          def required_param?
            true
          end

          def after_action(data, _config)
            show_models_tree(data)
          end
        end
      end
    end
  end
end
