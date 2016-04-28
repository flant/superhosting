module Superhosting
  module ConfigExecutor
    class Container < Base
      attr_accessor :container, :mux, :model

      def initialize(container:, model:, mux:, **kwargs)
        self.container = container
        self.mux = mux
        self.model = model
        super(**kwargs)
      end

      protected

      def base_mapper
        container
      end
    end
  end
end
