module Superhosting
  module Patches
    module PathMapper
      module Debug
        module NullNode
          include Superhosting::Helper::Logger

          def create!
            super.tap do
              self.debug(desc: { code: :directories_create, data: { path: @path } })
            end
          end

          def put!(content)
            super.tap do
              self.debug(desc: { code: :file_create, data: { path: @path } })
            end
          end

          def rename!(new_path)
            super.tap do
              self.debug(desc: { code: :file_rename, data: { path: @path, new_path: new_path } })
            end
          end

          def append!(content)
            super.tap do
              self.debug(desc: { code: :file_create, data: { path: @path } })
            end
          end
        end
      end
    end
  end
end

::PathMapper::NullNode.send(:prepend, Superhosting::Patches::PathMapper::Debug::NullNode)