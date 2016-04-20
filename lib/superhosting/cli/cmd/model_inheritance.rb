module Superhosting
  module Cli
    module Cmd
      class ModelInheritance < Base
        option :json,
               :long  => '--json',
               :boolean => true

        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          show_inheritance(data, config)
        end
      end
    end
  end
end