module Superhosting
  module Patches
    module PathMapper
      module Debug
        module DirNode
          include Superhosting::Helper::Logger

          def delete!(full: false)
            self.debug_operation(desc: { code: :directory_remove, data: { path: @path} }) do
              @path.rmtree

              path_ = @path.parent
              while path_.children.empty?
                self.debug_operation(desc: { code: :directory_remove, data: { path: path_} }) do
                  path_.rmdir
                  path_ = path_.parent
                end
              end if full

              ::PathMapper::NullNode.new(@path)
            end
          end

          def rename!(new_path)
            self.debug_operation(desc: { code: :directory_rename, data: { path: @path, new_path: new_path } }) do
              super
            end
          end
        end
      end
    end
  end
end

::PathMapper::DirNode.send(:prepend, Superhosting::Patches::PathMapper::Debug::DirNode)