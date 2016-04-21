module Superhosting
  module Cli
    module Cmd
      class ContainerSave < Base
        option :save_to,
               long: '--to'

        def self.required_param?
          true
        end
      end
    end
  end
end
