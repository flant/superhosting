module Superhosting
  module ConfigExecutor
    class Mux < Base
      attr_accessor :mux

      def initialize(mux:, **kwargs)
        self.mux = mux
        super(**kwargs)
      end

      protected

      def base_mapper
        mux
      end
    end
  end
end
