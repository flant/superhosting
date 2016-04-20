module Superhosting
  module Cli
    module Cmd
      class SiteAliasAdd < Base
        include Helper::Options::Site

        def self.has_required_param?
          true
        end
      end
    end
  end
end