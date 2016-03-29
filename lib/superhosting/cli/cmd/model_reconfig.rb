module Superhosting
  module Cli
    module Cmd
      class ModelReconfig < Base
        option :configure_only,
               :long  => '--configure-only'

        option :apply_only,
               :long  => '--apply-only'

        def self.has_required_param?
          true
        end
      end
    end
  end
end