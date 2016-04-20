module Superhosting
  module Cli
    module Cmd
      class AdminPasswd < Base
        include Helper::Options::Generate

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