module Superhosting
  module Cli
    module Helper
      module Options
        module Container
          extend ActiveSupport::Concern

          included do
            option :container_name,
                   :short => '-c NAME',
                   :long  => '--container NAME',
                   :required => true
          end
        end
      end
    end
  end
end
