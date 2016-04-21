module Superhosting
  module Cli
    module Cmd
      class SiteMove < Base
        option :new_container_name,
               short: '-c NAME',
               long: '--container-name NAME',
               required: true

        def self.required_param?
          true
        end
      end
    end
  end
end
