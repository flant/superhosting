module Superhosting
  module Cli
    module Cmd
      class SiteInheritance < Base
        include Helper::Options::Json

        def self.required_param?
          true
        end

        def self.after_action(data, config)
          show_inheritance(data, config)
        end
      end
    end
  end
end
