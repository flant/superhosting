module Superhosting
  module Cli
    module Cmd
      class SiteOptions < Base
        include Helper::Options::Inspect

        def self.required_param?
          true
        end

        def self.after_action(data, config)
          show_options(data, config)
        end
      end
    end
  end
end
