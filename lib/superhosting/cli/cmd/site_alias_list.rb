module Superhosting
  module Cli
    module Cmd
      class SiteAliasList < Base
        option :site_name,
               :short => '-s NAME',
               :long  => '--site NAME',
               :required => true

        def self.after_action(data, config)
          data.each {|a| self.info(a) }
        end
      end
    end
  end
end