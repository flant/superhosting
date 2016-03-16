module Superhosting
  module ScriptExecutor
    module ConfigMapper
      class Base < PathMapper::DirNode
        attr_accessor :etc_path, :lib_path, :web_path

        def initialize(etc_mapper:, lib_mapper:, web_mapper:)
          super(etc_mapper.path)
          self.inheritance = etc_mapper.inheritance
          self.etc_path = self
          self.lib_path = lib_mapper
          self.web_path = web_mapper
        end
      end
    end
  end
end