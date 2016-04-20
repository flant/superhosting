module Superhosting
  module Cli
    module Cmd
      class SiteAdd < Base
        include Helper::Options::Container

        def self.has_required_param?
          true
        end
      end
    end
  end
end