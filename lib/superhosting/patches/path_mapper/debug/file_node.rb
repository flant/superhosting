module Superhosting
  module Patches
    module PathMapper
      module Debug
        module FileNode
          include Superhosting::Helper::Logger

          def put!(content)
            self.debug_operation(desc: { code: :file_recreate, data: { path: @path } }) do
              super
            end
          end

          def append!(content)
            self.debug_operation(desc: { code: :file_append, data: { path: @path, content: content } }) do
              super
            end
          end

          def rename!(new_path)
            self.debug_operation(desc: { code: :file_rename, data: { path: @path, new_path: new_path } }) do
              super
            end
          end

          def delete!(full: false)
            self.debug_operation(desc: { code: :file_remove, data: { path: @path } }) do
              super
            end
          end
        end
      end
    end
  end
end

::PathMapper::FileNode.send(:prepend, Superhosting::Patches::PathMapper::Debug::FileNode)