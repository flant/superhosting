module Superhosting
  module Cli
    module Cmd
      class ModelList < Base
        option :abstract,
               :long  => '--abstract',
               :boolean => true

        option :json,
               :long  => '--json',
               :boolean => true

        def self.after_action(data, config)
          show_model_list(data, config)
        end
      end
    end
  end
end