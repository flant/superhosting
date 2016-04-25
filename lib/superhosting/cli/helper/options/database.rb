module Superhosting
  module Cli
    module Helper
      module Options
        module Database
          extend ActiveSupport::Concern

          included do
            option :databases,
                   short: '-d NAME',
                   long: '--database NAME',
                   default: [],
                   proc: Proc.new { |l| l.to_sym },
                   required: true
          end
        end
      end
    end
  end
end
