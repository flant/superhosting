module Superhosting
  module Cli
    module Helper
      module Options
        module Model
          extend ActiveSupport::Concern

          included do
            option :model,
                   short: '-m MODEL',
                   long: '--model MODEL'
          end
        end
      end
    end
  end
end
