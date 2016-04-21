module Superhosting
  module Cli
    module Helper
      module Options
        module Inspect
          extend ActiveSupport::Concern
          include Inheritance

          included do
            option :erb,
                   long: '--erb',
                   boolean: true
          end
        end
      end
    end
  end
end
