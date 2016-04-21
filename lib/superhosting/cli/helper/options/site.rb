module Superhosting
  module Cli
    module Helper
      module Options
        module Site
          extend ActiveSupport::Concern

          included do
            option :site_name,
                   :short => '-s NAME',
                   :long => '--site NAME',
                   :required => true
          end
        end
      end
    end
  end
end
