module Superhosting
  module Cli
    module Cmd
      class ContainerModelTree < Base
        option :container_name,
               :short => '-c NAME',
               :long  => '--container NAME',
               :required => true

        def self.after_action(data, config)
          ModelTree.show_models_tree(data)
        end
      end
    end
  end
end