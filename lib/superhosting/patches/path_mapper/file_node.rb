module Superhosting
  module Patches
    module PathMapper
      module FileNode
        include Helper

        def _put!(content)
          _action!(:file, path: @path) { super }
        end

        def _safe_put!(content)
          _action!(:file, path: @path) { super }
        end

        def _remove_line!(line)
          _action!(:file, path: @path) { super }
        end

        def _append_line!(content)
          _action!(:file, path: @path) { super }
        end

        def _rename!(new_path)
          _action!(:file, path: @path, to: new_path) { super }
        end

        def _delete!(full: false)
          _action!(:file, path: @path) { super }
        end
      end
    end
  end
end

::PathMapper::FileNode.send(:prepend, Superhosting::Patches::PathMapper::FileNode)
