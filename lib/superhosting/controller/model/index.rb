module Superhosting
  module Controller
    class Model
      def index
        index = {}
        @container_controller._list.each do |container_name, data|
          model = @container_controller.index[container_name][:model_name]
          (index[model] ||= []) << container_name
        end
        index
      end
    end
  end
end