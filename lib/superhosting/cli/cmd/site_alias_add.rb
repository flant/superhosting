module Superhosting
  module Cli
    module Cmd
      class SiteAliasAdd < Base
        option :site_name,
               :short => '-s',
               :long  => '--site'

        def self.superbanner(path=[])
          self.banner("sx #{path.join(' ')} <name> #{'(options)' unless self.options.empty?}")
        end

        def run
          
        end
      end
    end
  end
end