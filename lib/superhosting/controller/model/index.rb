module Superhosting
  module Controller
    class Model
      def index
        index = {}
        @container_controller._list.each do |container_info|
          container_name = container_info['name']
          model = @container_controller.index[container_name].model_name
          (index[model] ||= []) << container_name
        end
        index
      end
    end
  end
end
