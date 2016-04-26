module Superhosting
  module Cli
    module Helper
      module Options
        module NotRequiredContainer
          extend ActiveSupport::Concern

          included do
            option :container_name,
                   short: '-c NAME',
                   long: '--container NAME'
          end
        end
      end
    end
  end
end
