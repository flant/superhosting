module Superhosting
  module Cli
    module Cmd
      class SiteRename < Base
        option :new_name,
               :short => '-r NAME',
               :long  => '--new-name NAME',
               :required => true

        def self.has_required_param?
          true
        end
      end
    end
  end
end