module Superhosting
  module Cli
    module Cmd
      class SiteRename < Base
        include Helper::Options::NewName

        option :keep_name_as_alias,
               :short => '-k',
               :long => '--keep-name-as-alias',
               :bollean => true

        def self.has_required_param?
          true
        end
      end
    end
  end
end