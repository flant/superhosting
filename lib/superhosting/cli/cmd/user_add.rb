module Superhosting
  module Cli
    module Cmd
      class UserAdd < Base
        option :ftp_only,
               :short => '-f',
               :long  => '--ftp-only',
               :boolean => true

        option :ftp_dir,
               :short => '-d',
               :long  => '--ftp-dir DIR'

        option :container_name,
               :short => '-c NAME',
               :long  => '--container NAME',
							 :required => true

        option :generate,
               :short => '-g',
               :long  => '--generate',
               :boolean => true

        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          show_data(data)
        end
      end
    end
  end
end