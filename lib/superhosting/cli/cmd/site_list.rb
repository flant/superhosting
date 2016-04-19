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

        class << self
          def after_action(data, config)
            data = data.uniq {|v| v['name'] }
            if config[:json]
              self.info_pretty_json(data.map do |site_info|
                {
                    'name' => site_info['name'],
                    'state' => site_info['state'],
                    'container' => site_info['container'],
                    'aliases' => site_info['aliases']
                }
              end)
            else
              data.each do |site_info|
                name = site_info['name']
                container = site_info['container']
                state = site_info['state']

                output = []
                output << container unless config[:container_name]
                output << name
                output << state if config[:state]

                self.info(output.join(' '))
              end
            end
          end
        end
      end
    end
  end
end