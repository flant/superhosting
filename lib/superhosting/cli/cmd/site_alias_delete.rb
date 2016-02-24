module Superhosting
  module Cli
    module Cmd
      class SiteAliasDelete < Base
        option :site_name,
               :short => '-s NAME',
               :long  => '--site NAME',
							 :required => true

        def self.has_required_param?
          true
        end
      end
    end
  end
end