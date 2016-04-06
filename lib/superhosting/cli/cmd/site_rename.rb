module Superhosting
  module Cli
    module Cmd
      class SiteRename < Base
        option :new_name,
               :short => '-r NAME',
               :long  => '--new-name NAME',
               :required => true

        option :alias_name,
               :long  => '--alias-name',
               :bollean => true

        def self.has_required_param?
          true
        end
      end
    end
  end
end