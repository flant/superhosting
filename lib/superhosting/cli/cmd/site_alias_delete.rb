module Superhosting
  module Cli
    module Cmd
      class SiteAliasDelete < Base
        option :alias_name,
               :short => '-a NAME',
               :long  => '--alias NAME',
               :required => true

        def self.has_required_param?
          true
        end
      end
    end
  end
end