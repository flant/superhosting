module Superhosting
  module Cli
    module Cmd
      class SiteList < Base
        include Helper::Options::List
        include Helper::Options::State

        option :container_name,
               :short => '-c NAME',
               :long  => '--container NAME',
               :required => false

        def self.after_action(data, config)
          show_site_list(data, config)
        end
      end
    end
  end
end