module Superhosting
  module Controller
    class Container
      class Model < Base
        def initialize(name:, **kwargs)
          super(kwargs)
          @container_name = name
          @container_controller = self.get_controller(Container)
        end

        def tree
          if (resp = @container_controller.existing_validation(name: @container_name)).net_status_ok?
            model_controller = self.get_controller(Controller::Model)
            tree = model_controller.tree(name: @container_controller.index[@container_name][:model_name]).net_status_ok![:data]
            { data: tree }
          else
            resp
          end
        end

        def name
          if (resp = @container_controller.existing_validation(name: @container_name)).net_status_ok?
            { data: @container_controller.index[@container_name][:model_name] }
          else
            resp
          end
        end
      end
    end
  end
end
