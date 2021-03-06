module Superhosting
  module Cli
    module Cmd
      class AdminAdd < Base
        include Helper::Options::Generate

        def self.required_param?
          true
        end

        def self.after_action(data, _config)
          show_data(data)
        end
      end
    end
  end
end
