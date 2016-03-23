module Superhosting
  module Patches
    module PathMapper
      module Debug
        module FileNode
          include Superhosting::Helper::Logger

          def delete!(full: false)
            super.tap do
              self.debug(desc: { code: :file_remove, data: { path: @path } })
            end
          end
        end
      end
    end
  end
end

::PathMapper::FileNode.send(:prepend, Superhosting::Patches::PathMapper::Debug::FileNode)