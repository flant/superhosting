module Superhosting
  module Cli
    module Helper
      module Options
        module Inheritance
          extend ActiveSupport::Concern

          included do
            option :inheritance,
                   :long  => '--inheritance',
                   :boolean => true
          end
        end
      end
    end
  end
end
