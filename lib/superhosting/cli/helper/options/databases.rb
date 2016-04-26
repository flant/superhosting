module Superhosting
  module Cli
    module Helper
      module Options
        module Databases
          extend ActiveSupport::Concern

          included do
            option :databases,
                   short: '-d NAME',
                   long: '--database NAME',
                   default: [],
                   proc: Proc.new { |d| @composite_options ||= {}; (@composite_options[:databases] ||= []) << d },
                   required: false
          end
        end
      end
    end
  end
end
