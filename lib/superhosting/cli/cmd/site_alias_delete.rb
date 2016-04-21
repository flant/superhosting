module Superhosting
  module Cli
    module Cmd
      class SiteAliasDelete < Base
        include Helper::Options::Site

        def self.required_param?
          true
        end
      end
    end
  end
end
