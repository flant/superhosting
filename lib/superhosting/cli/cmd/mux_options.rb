module Superhosting
  module Cli
    module Cmd
      class MuxOptions < Base
        option :inheritance,
               :long  => '--inheritance',
               :boolean => true

        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          show_options(data, config)
        end
      end
    end
  end
end