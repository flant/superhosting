module Superhosting
  module Cli
    module Helper
      module Options
        module Users
          extend ActiveSupport::Concern

          included do
            option :users,
                   short: '-u NAME',
                   long: '--user NAME',
                   default: [],
                   proc: Proc.new { |d| @composite_options ||= {}; (@composite_options[:users] ||= []) << d },
                   required: false
          end
        end
      end
    end
  end
end
