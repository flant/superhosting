module Superhosting
  module Cli
    module Cmd
      class SiteAliasList < Base
        include Helper::Options::List
        include Helper::Options::Site

        def self.after_action(data, config)
          show_alias_list(data, config)
        end
      end
    end
  end
end
