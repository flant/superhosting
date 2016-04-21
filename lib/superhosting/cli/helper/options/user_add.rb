module Superhosting
  module Cli
    module Helper
      module Options
        module UserAdd
          extend ActiveSupport::Concern

          included do
            option :ftp_only,
                   :short => '-f',
                   :long => '--ftp-only',
                   :boolean => true

            option :ftp_dir,
                   :short => '-d',
                   :long => '--ftp-dir DIR'

            option :generate,
                   :short => '-g',
                   :long => '--generate',
                   :boolean => true
          end
        end
      end
    end
  end
end
