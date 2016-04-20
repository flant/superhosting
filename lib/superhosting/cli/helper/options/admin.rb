module Superhosting
  module Cli
    module Helper
      module Options
        module Admin
          extend ActiveSupport::Concern

          included do
            option :admin_name,
                   :short => '-a NAME',
                   :long  => '--admin NAME',
                   :required => true
          end
        end
      end
    end
  end
end
