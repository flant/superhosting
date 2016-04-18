module Superhosting
  module Cli
    module Cmd
      class MuxInheritance < Base
        option :json,
               :long  => '--json',
               :boolean => true

        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          if config[:json]
            self.info_pretty_json(data)
          else
            self.info(data.map {|hash| hash['name'] })
          end
        end
      end
    end
  end
end