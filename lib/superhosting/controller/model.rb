module Superhosting
  module Controller
    class Model < Base
      def initialize(**kwargs)
        super
        @container_controller = self.get_controller(Container)
      end

      def list
        models = []
        @config.models.grep_dirs.each do |model_mapper|
          models << model_mapper.name unless model_mapper.abstract?
        end
        { data: models }
      end

      def tree

      end

      def reconfig(name:, configure_only: nil, apply_only: nil)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          self.index[name].each do |container_name|
            break unless (resp = @container_controller.reconfig(name: container_name, configure_only: configure_only, apply_only: apply_only)).net_status_ok?
          end
        end
        resp
      end

      def update(name:)

      end

      def existing_validation(name:)
        self.index.include?(name) ? {} : { error: :logical_error, code: :model_does_not_exists, data: { name: name } }
      end

      def index
        def generate
          @index = {}
          @container_controller.list[:data].each do |container|
            container_mapper = @config.containers.f(container[:name])
            model = container_mapper.f('model', default: @config.default_model).value
            (@index[model] ||= []) << container[:name]
          end

          @index
        end

        @index || generate
      end
    end
  end
end