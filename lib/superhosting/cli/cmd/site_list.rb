module Superhosting
  module Cli
    module Cmd
      class SiteList < Base
        option :container_name,
               :short => '-c NAME',
               :long  => '--container NAME',
               :required => true
      end
    end
  end
end