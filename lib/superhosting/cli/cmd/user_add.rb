module Superhosting
  module Cli
    module Cmd
      class UserAdd < Base
        include Helper::Options::UserAdd
        include Helper::Options::Container

        def self.has_required_param?
          true
        end

        def self.after_action(data, _config)
          show_data(data)
        end
      end
    end
  end
end