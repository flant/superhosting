module Superhosting
  module CompositeMapper
    class Mux
      include Helper::Logger
      attr_accessor :lib

      def initialize(lib_mapper:)
        self.lib = lib_mapper
      end

      def method_missing(m, *args, &block)
        if lib.nil?
          warn('No mux available!')
        else
          lib.send(m, *args, &block)
        end
      end

      def config
        lib.config
      end

      def name
        "mux-#{lib.name}"
      end
    end
  end
end
