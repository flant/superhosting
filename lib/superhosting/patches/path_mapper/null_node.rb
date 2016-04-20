module Superhosting
  module Patches
    module PathMapper
      module NullNode
        include Helper

        def _create!
          _action!(:directory, { path: @path }) { super }
        end

        def _safe_put!(content)
          _action!(:file, { path: @path }) { super }
        end

        def _put!(content)
          _action!(:file, { path: @path }) { super }
        end

        def _append_line!(content)
          _action!(:file, { path: @path }) { super }
        end
      end
    end
  end
end

::PathMapper::NullNode.send(:prepend, Superhosting::Patches::PathMapper::NullNode)