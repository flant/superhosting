module Superhosting
  module Cli
    module Cmd
      class MysqlDbAdd < Base
        include Helper::Options::NotRequiredContainer
        include Helper::Options::Generate
        include Helper::Options::Users

        def self.required_param?
          true
        end

        def self.after_action(data, _config)
          show_list(data)
        end
      end
    end
  end
end
