module Superhosting
  module Cli
    module Cmd
      class SiteAliasList < Base
        option :site_name,
               :short => '-s NAME',
               :long  => '--site NAME',
               :required => true

        option :json,
               :long  => '--json',
               :boolean => true

        def self.after_action(data, config)
          show_alias_list(data, config)
        end
      end
    end
  end
end