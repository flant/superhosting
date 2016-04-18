module Superhosting
  module Cli
    module Cmd
      class ContainerList < Base
        option :state,
               :long  => '--state',
               :boolean => true

        option :json,
               :long  => '--json',
               :boolean => true

        def self.after_action(data, config)
          data.each do |container_info|
            name = container_info['name']
            state = container_info['state']
            if config['state']
              self.info([name, state].join(' '))
            elsif config[:json]
              self.info_pretty_json('name' => name, 'state' => state)
            else
              self.info(name)
            end
          end
        end
      end
    end
  end
end