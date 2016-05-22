module Superhosting
  module Controller
    class Model
      def index
        index = {}
        @container_controller.index.each do |container_name, container_index|
          (index[container_index.model_name] ||= []) << container_name
        end
        index
      end
    end
  end
end
