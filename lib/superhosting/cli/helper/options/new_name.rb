module Superhosting
  module Cli
    module Helper
      module Options
        module NewName
          extend ActiveSupport::Concern

          included do
            option :new_name,
                   short: '-r NAME',
                   long: '--new-name NAME',
                   required: true
          end
        end
      end
    end
  end
end
