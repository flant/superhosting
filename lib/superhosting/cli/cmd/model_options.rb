module Superhosting
  module Cli
    module Cmd
      class ModelOptions < Base
        include Helper::Options::Inheritance

        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          show_options(data, config)
        end
      end
    end
  end
end