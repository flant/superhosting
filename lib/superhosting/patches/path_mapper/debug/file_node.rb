module Superhosting
  module Patches
    module PathMapper
      module Debug
        module FileNode
          include Superhosting::Helper::Logger

          def put!(content)
            self.pretty_debug(desc: { code: :file_recreate, data: { path: @path } }) do
              super
            end
          end

          def append!(content)
            self.pretty_debug(desc: { code: :file_append, data: { path: @path, content: content } }) do
              super
            end
          end

          def remove_line!(line)
            self.pretty_debug(desc: { code: :file_remove_line, data: { path: @path, line: line } }) do
              super
            end
          end

          def rename!(new_path)
            self.pretty_debug(desc: { code: :file_rename, data: { path: @path, new_path: new_path } }) do
              super
            end
          end

          def delete!(full: false)
            self.pretty_debug(desc: { code: :file_remove, data: { path: @path } }) do
              super
            end
          end
        end
      end
    end
  end
end

::PathMapper::FileNode.send(:prepend, Superhosting::Patches::PathMapper::Debug::FileNode)