module Superhosting
  module Controller
    class Model
      def index
        index = {}
        @container_controller._list.each do |container_name, data|
          container_mapper = @container_controller.index[container_name][:mapper]
          model = container_mapper.f('model', default: @config.default_model).value

          (index[model] ||= []) << container_name
        end
        index
      end
    end
  end
end