module Superhosting
  module Patches
    module PathMapper
      module Debug
        module DirNode
          include Superhosting::Helper::Logger

          def delete!(full: false)
            @path.rmtree
            self.debug(desc: { code: :directory_remove, data: { path: @path} })

            path_ = @path.parent
            while path_.children.empty?
              path_.rmdir
              path_ = path_.parent
              self.debug(desc: { code: :directory_remove, data: { path: path_} })
            end if full

            ::PathMapper::NullNode.new(@path)
          end

          def rename!(new_path)
            super.tap do
              self.debug(desc: { code: :directory_rename, data: { path: @path, new_path: new_path } })
            end
          end
        end
      end
    end
  end
end

::PathMapper::DirNode.send(:prepend, Superhosting::Patches::PathMapper::Debug::DirNode)