module Superhosting
  module Cli
    module Helper
      module Options
        module Json
          extend ActiveSupport::Concern

          included do
            option :json,
                   long: '--json',
                   boolean: true
          end
        end
      end
    end
  end
end
