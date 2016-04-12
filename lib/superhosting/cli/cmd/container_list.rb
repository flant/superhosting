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
          data.each do |k,v|
            if config[:state]
              self.info("#{k} #{v[:state]}")
            elsif config[:json]
              self.info(name: k, state: v[:state])
            else
              self.info(k)
            end
          end
        end
      end
    end
  end
end