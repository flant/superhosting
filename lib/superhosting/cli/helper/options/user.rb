module Superhosting
  module Cli
    module Helper
      module Options
        module User
          extend ActiveSupport::Concern

          included do
            option :user_name,
                   short: '-u NAME',
                   long: '--user NAME',
                   required: false
          end
        end
      end
    end
  end
end
