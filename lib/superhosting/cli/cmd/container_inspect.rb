module Superhosting
  module Cli
    module Cmd
      class ContainerInspect < Base
        include Helper::Options::Inspect

        def self.required_param?
          true
        end

        def self.after_action(data, _config)
          show_json(data)
        end
      end
    end
  end
end
