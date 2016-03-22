module Superhosting
  module Controller
    class Model < Base
      def list
        models = []
        @config.models.grep_dirs.each do |model_mapper|
          models << model_mapper.name unless model_mapper.abstract?
        end
        { data: models }
      end

      def tree

      end

      def reconfig(name:)

      end

      def update(name:)

      end
    end
  end
end