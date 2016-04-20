module Superhosting
  module Patches
    module PathMapper
      module DirNode
        include Helper

        def _delete!(full: false)
          _action!(:directory, { path: @path }) { super }
        end

        def _rename!(new_path)
          _action!(:directory, { path: @path, to: new_path }) { super }
        end
      end
    end
  end
end

::PathMapper::DirNode.send(:prepend, Superhosting::Patches::PathMapper::DirNode)