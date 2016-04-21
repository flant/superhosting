module Superhosting
  module Cli
    module Helper
      module Options
        module Generate
          extend ActiveSupport::Concern

          included do
            option :generate,
                   :short => '-g',
                   :long => '--generate',
                   :boolean => true
          end
        end
      end
    end
  end
end
