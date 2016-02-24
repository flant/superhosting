module Superhosting
  module Cli
    module Cmd
      class UserChange < Base
        option :no_ssh,
               :short => '-s',
               :long  => '--no-ssh'

        option :no_ftp,
               :short => '-f',
               :long  => '--no-ftp'

        option :container_name,
               :short => '-c NAME',
               :long  => '--container NAME',
							 :required => true

        def self.has_required_param?
          true
        end
      end
    end
  end
end