module Superhosting
  module Cli
    module Cmd
      class SiteList < Base
        include Helper::Options::List
        include Helper::Options::State
        include Helper::Options::NotRequiredContainer

        def self.after_action(data, config)
          show_site_list(data, config)
        end
      end
    end
  end
end
