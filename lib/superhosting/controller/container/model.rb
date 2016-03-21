module Superhosting
  module Controller
    class Container
      class Model < Base
        attr_writer :model_index

        def initialize(**kwargs)
          super(kwargs)
          @container_controller = self.get_controller(Container)
        end

        def reconfig(name:)
          if (resp = self.existing_validation(name: name)).net_status_ok?
            self.model_index[name].each do |container_name|
              break unless (resp = @container_controller.reconfig(name: container_name)).net_status_ok?
            end
          end
          resp
        end

        def existing_validation(name:)
          self.model_index.include?(name) ? {} : { error: :logical_error, code: :model_does_not_exists, data: { name: name } }
        end

        def model_index
          def generate
            @model_index = {}
            @container_controller.container_index.each do |container_name, v|
              model = @config.containers.f(container_name).f('model', default: @config.default_model).value
              model_mapper = @config.models.f(model)
              if model_mapper.dir?
                (@model_index[model] ||= []) << container_name
              end
            end

            @model_index
          end

          @model_index || generate
        end
      end
    end
  end
end