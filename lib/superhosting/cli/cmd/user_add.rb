module Superhosting
  module Cli
    module Cmd
      class UserAdd < Base
        option :no_ssh,
               :long  => '--no-ssh',
               :boolean => true

        option :no_ftp,
               :long  => '--no-ftp',
               :boolean => true

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