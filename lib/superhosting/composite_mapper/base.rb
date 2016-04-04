module Superhosting
  module CompositeMapper
    class Base
      attr_accessor :etc, :lib, :web

      def initialize(etc_mapper:, lib_mapper:, web_mapper:)
        self.etc = etc_mapper
        self.lib = lib_mapper
        self.web = web_mapper
      end

      def method_missing(m, *args, &block)
        self.etc.send(m, *args, &block)
      end
    end
  end
end