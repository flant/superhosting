module Superhosting
  module Patches
    module PathMapper
      module NullNode
        include Helper::Logger

        def _create!
          self.debug_operation(desc: { code: :directory, data: { path: @path } }) do |&blk|
            super.tap {|res| blk.call(code: res[:code], diff: res[:d][:diff]) }
          end
        end

        def _put!(content)
          self.debug_operation(desc: { code: :file, data: { path: @path } }) do |&blk|
            super.tap {|res| blk.call(code: res[:code], diff: res[:d][:diff]) }
          end
        end

        def _append_line!(content)
          self.debug_operation(desc: { code: :file, data: { path: @path } }) do |&blk|
            super.tap {|res| blk.call(code: res[:code], diff: res[:d][:diff]) }
          end
        end
      end
    end
  end
end

::PathMapper::NullNode.send(:prepend, Superhosting::Patches::PathMapper::NullNode)