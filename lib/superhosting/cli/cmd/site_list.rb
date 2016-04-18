module Superhosting
  module Cli
    module Cmd
      class SiteList < Base
        option :container_name,
               :short => '-c NAME',
               :long  => '--container NAME',
               :required => false

        option :state,
               :long  => '--state',
               :boolean => true

        option :json,
               :long  => '--json',
               :boolean => true

        def self.after_action(data, config)
          data.each do |site_info|
            name = site_info['name']
            container = site_info['container']
            state = site_info['state']
            aliases = site_info['aliases']

            output = []
            output << container unless config[:container_name]
            output << name
            output << state if config[:state]

            if config[:json]
              self.info_pretty_json('name' => name, 'state' => state, 'aliases' => aliases, 'container' => container)
            else
              self.info(output.join(' '))
            end
          end
        end
      end
    end
  end
end