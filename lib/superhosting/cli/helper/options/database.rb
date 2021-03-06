module Superhosting
  module Cli
    module Helper
      module Options
        module Database
          extend ActiveSupport::Concern

          included do
            option :database_name,
                   short: '-d NAME',
                   long: '--database NAME',
                   required: true
          end
        end
      end
    end
  end
end
