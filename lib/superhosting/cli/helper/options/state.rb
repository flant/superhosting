module Superhosting
  module Cli
    module Helper
      module Options
        module State
          extend ActiveSupport::Concern

          included do
            option :state,
                   :long  => '--state',
                   :boolean => true
          end
        end
      end
    end
  end
end
