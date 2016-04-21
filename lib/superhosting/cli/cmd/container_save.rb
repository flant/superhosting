module Superhosting
  module Cli
    module Cmd
      class ContainerSave < Base
        option :save_to,
               :long => '--to'

        def self.has_required_param?
          true
        end
      end
    end
  end
end