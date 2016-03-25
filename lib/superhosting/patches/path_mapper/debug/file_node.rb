module Superhosting
  module Patches
    module PathMapper
      module Debug
        module FileNode
          include Superhosting::Helper::Logger

          def put!(content)
            super.tap do
              self.debug(desc: { code: :file_recreate, data: { path: @path } })
            end
          end

          def append!(content)
            super.tap do
              self.debug(desc: { code: :file_append, data: { path: @path, content: content } })
            end
          end

          def remove_line!(line)
            super.tap do
              self.debug(desc: { code: :file_remove_line, data: { path: @path, line: line } })
            end
          end

          def rename!(new_path)
            super.tap do
              self.debug(desc: { code: :file_rename, data: { path: @path, new_path: new_path } })
            end
          end

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