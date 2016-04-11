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

        def self.after_action(data, config, logger)
          data.each do |k,v|
            if config[:state]
              logger.info("#{k} #{v[:state]}")
            elsif config[:json]
              logger.info(name: k, state: v[:state])
            else
              logger.info(k)
            end
          end
        end
      end
    end
  end
end