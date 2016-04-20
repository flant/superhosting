module Superhosting
  module Cli
    module Cmd
      class SiteContainer < Base
        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          show_data(data)
        end
      end
    end
  end
end