module Superhosting
  module Cli
    module Cmd
      class SiteInspect < Base
        option :inheritance,
               :long  => '--inheritance',
               :boolean => true

        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          self.info(JSON.pretty_generate(data))
        end
      end
    end
  end
end