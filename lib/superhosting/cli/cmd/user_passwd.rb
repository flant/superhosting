module Superhosting
  module Cli
    module Cmd
      class UserPasswd < Base
        option :generate,
               :short => '-g',
               :long  => '--generate',
               :boolean => true

        option :container_name,
               :short => '-c NAME',
               :long  => '--container NAME',
               :required => true

        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          self.info(data)
        end
      end
    end
  end
end