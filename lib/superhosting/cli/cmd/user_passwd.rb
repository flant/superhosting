module Superhosting
  module Cli
    module Cmd
      class UserPasswd < Base
        include Helper::Options::Container
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
