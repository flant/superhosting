module Superhosting
  module Cli
    module Cmd
      class ModelInspect < Base
        include Helper::Options::Inheritance

        def self.has_required_param?
          true
        end

        def self.after_action(data, _config)
          show_json(data)
        end
      end
    end
  end
end