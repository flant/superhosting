module Superhosting
  module Cli
    module Cmd
      class SiteOptions < Base
        option :inheritance,
               :long  => '--inheritance',
               :boolean => true

        option :erb,
               :long  => '--erb',
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