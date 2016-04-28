module Superhosting
  module CompositeMapper
    class Mux
      include Helper::Logger
      attr_accessor :lib, :etc

      def initialize(etc_mapper:, lib_mapper:)
        self.etc = etc_mapper
        self.lib = lib_mapper
      end

      def method_missing(m, *args, &block)
        if etc.nil?
          warn('No mux available!')
        else
          etc.send(m, *args, &block)
        end
      end

      def config
        lib.config
      end

      def container_name
        "mux-#{lib.name}"
      end
    end
  end
end
