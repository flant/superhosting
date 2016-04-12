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
          data.each do |k,v|
            output = []
            output << v[:container] unless config[:container_name]
            output << k
            output << v[:state] if config[:state]

            if config[:json]
              logger.info(name: k, state: v[:state], aliases: v[:aliases], container: v[:container])
            else
              logger.info(output.join(' '))
            end
          end
        end
      end
    end
  end
end