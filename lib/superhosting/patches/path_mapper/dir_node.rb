module Superhosting
  module Patches
    module PathMapper
      module DirNode
        include Helper::Logger

        def _delete!(full: false)
          self.debug_operation(desc: { code: :directory, data: { path: @path } }) do |&blk|
            super.tap {|res| blk.call(code: res[:code], diff: res[:d][:diff]) }
          end
        end

        def _rename!(new_path)
          self.debug_operation(desc: { code: :directory, data: { path: @path } }) do |&blk|
            super.tap {|res| blk.call(code: res[:code], diff: res[:d][:diff]) }
          end
        end
      end
    end
  end
end

::PathMapper::DirNode.send(:prepend, Superhosting::Patches::PathMapper::DirNode)