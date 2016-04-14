module Superhosting
  module Controller
    class Model < Base
      def initialize(**kwargs)
        super
        @container_controller = self.get_controller(Container)
      end

      def list
        { data: self._list }
      end

      def _list
        models = []
        @config.models.grep_dirs.each do |model_mapper|
          models << model_mapper.name unless model_mapper.abstract?
        end
        models
      end

      def tree(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          { data: MapperInheritance::Model.new(@config.models.f(name)).collect_inheritors_tree }
        else
          resp
        end
      end

      def reconfigure(name:)
        if (resp = self.useable_validation(name: name)).net_status_ok?
          self.index[name].each do |container_name|
            break unless (resp = @container_controller.reconfigure(name: container_name)).net_status_ok?
          end
        end
        resp
      end

      def update(name:)
        if (resp = self.useable_validation(name: name)).net_status_ok?
          self.index[name].each do |container_name|
            break unless (resp = @container_controller.update(name: container_name)).net_status_ok?
          end
        end
        resp
      end

      def useable_validation(name:)
        self.index.include?(name) ? {} : { error: :logical_error, code: :model_does_not_used, data: { name: name } }
      end

      def existing_validation(name:)
        self._list.include?(name) ? {} : { error: :logical_error, code: :model_does_not_exists, data: { name: name } }
      end

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