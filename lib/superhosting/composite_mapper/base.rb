module Superhosting
  module CompositeMapper
    class Base < PathMapper::DirNode
      attr_accessor :etc, :lib, :web

      def initialize(etc_mapper:, lib_mapper:, web_mapper:)
        super(etc_mapper.path)
        self.inheritance = etc_mapper.inheritance
        self.etc = self
        self.lib = lib_mapper
        self.web = web_mapper
      end
    end
  end
end